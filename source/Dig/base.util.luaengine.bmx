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

	Copyright (C) 2002-2021 Ronny Otto, digidea.de

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


Type TLuaEngineSuperDummy
End Type
Global LuaEngineSuperDummy:TLuaEngineSuperDummy = new TLuaEngineSuperDummy


Type TLuaEngine
	Global dieOnError:Int = False
	?debug
		Global notifyOnError:Int = True
	?not debug
		Global notifyOnError:Int = False
	?
	'-1 to deactivate limit, > 0 to deactivate notification once it reaches 0
	Global notifyOnErrorLimit:Int = 1
	Global debugCalls:Int = True

	Global list:TList = CreateList()
	Global lastID:Int = 0
	Global _listMutex:TMutex = CreateMutex()
	Field id:Int = 0

	'-1 to deactivate limit, > 0 to deactivate notification once it reaches 0
	'this is done on a "per engine" base to be able to
	'spot different errors
	Field individualNotifyOnErrorLimit:Int


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
		Local obj:TLuaEngine = New TLuaEngine
		obj._uri = uri
		'add here so during "RegisterToLua" code could run already
		LockMutex(_listMutex)
		list.addLast(obj)
		UnLockMutex(_listMutex)
		
		
		obj.individualNotifyOnErrorLimit = TLuaEngine.notifyOnErrorLimit

		'init fenv and register self (if some lua code was passed)
		If not source and uri then source = LoadText(uri)
		If source
			'assign new lua script code
			obj.SetSource(source)
			'register code handlers
			obj.RegisterToLua()
		EndIf

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
		if _luaState
			luaL_unref(getLuaState(), LUA_REGISTRYINDEX, _functionEnvironmentRef)
			luaL_unref(getLuaState(), LUA_REGISTRYINDEX, _chunk)
			luaL_unref(getLuaState(), LUA_REGISTRYINDEX, _objMetaTable)

			lua_close(_luaState)
			_luaState = Null
		endif
	End Method


	Function RemoveEngine(engine:TLuaEngine)
		LockMutex(_listMutex)
		list.Remove(engine)
		UnlockMutex(_listMutex)
		TLogger.Log("TLuaEngine", "RemoveEngine(): engine removed.", LOG_DEBUG)
	End Function


	Function FindEngine:TLuaEngine(LuaState:Byte Ptr)
		LockMutex(_listMutex)
		Local result:TLuaEngine
		For Local engine:TLuaEngine = EachIn TLuaEngine.list
			If engine._luaState = LuaState 
				result = engine
				exit
			EndIf
		Next
		UnLockMutex(_listMutex)

		if not result Then TLogger.Log("TLuaEngine", "FindEngine(): engine not found.", LOG_ERROR)
		Return result
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
		'push class block / current lua script code
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

		lua_pushobject(LuaEngineSuperDummy)
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
		If lua_pcall(getLuaState(), 0, 0, 0 ) <> 0 Then DumpError("Initialization Error")
	End Method


	Method BlackListFunctions()
		For Local entry:String = EachIn _blacklistedFunctions
			lua_pushnil(getLuaState())
			lua_setglobal(getLuaState(), entry)
		Next
	EndMethod
	
	
	Method DumpError(errorType:String = "Error")
		Local error:String = lua_tostring( getLuaState(), -1 )
		lua_pop(GetLuaState(), 1) 'remove error from stack
		Local split:String[] = error.split("~nstack traceback:~n")
		Local errorMessage:String = split[0]
		Local errorBacktraceLines:String[]
		if split.length > 1 then errorBacktraceLines = split[1].split("~n")
		
		TLogger.Log("TLuaEngine", "#### " + errorType + " (Engine " + id +") #######################", LOG_ERROR)
		TLogger.Log("TLuaEngine", "Error: " + errorMessage, LOG_ERROR)
		if errorBacktraceLines.length > 0
			TLogger.Log("TLuaEngine", "Backtrace: ", LOG_ERROR)
			For local line:String = EachIn errorBacktraceLines
				Tlogger.Log("TLuaEngine", "    " + line.trim(), LOG_ERROR)
			Next
		EndIf
		
		If notifyOnError And individualNotifyOnErrorLimit <> 0
			notify("TLuaEngine: " + errorType +" (Engine " + id +")~nError:" + errorMessage)
			If individualNotifyOnErrorLimit > 0
				individualNotifyOnErrorLimit :- 1
			EndIf
		EndIf
		if dieOnError then Throw("TLuaEngine: " + errorType + " (Engine " + id +"):" + errorMessage)
	End Method


	Method lua_pushChunk:Int()
		If Not _chunk
			If luaL_loadstring(getLuaState(), _source)
				DumpError("Syntax Error")
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
			'create metatable if not done yet
			getObjMetaTable()

			lua_boxobject(getLuaState(), obj)
			lua_rawgeti(getLuaState(), LUA_REGISTRYINDEX, _objMetaTable)
			lua_setmetatable(getLuaState(),-2)
		EndIf
	End Method


	'===== CODE FROM MAXLUA ====
	'but added _private / _expose ... checks, also added method/function
	'identification with parameter offset handling and other things

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
		'ignore this LuaEngineSuperdummy, it is passed if Lua scripts
		'call Lua-objects and functions ("toNumber", "pairs")
		If obj = LuaEngineSuperDummy Then Return False

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
			?not bmxng
			If callable.MetaData("_private")
			?bmxng
			If callable.HasMetaData("_private")
			?
				If TMethod(callable)
					TLogger.Log("TLuaEngine", "[Engine " + id + "] Object "+typeId.name()+" does not expose method ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				Else
					TLogger.Log("TLuaEngine", "[Engine " + id + "] Object "+typeId.name()+" does not expose function ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				EndIf
				Return False
			EndIf
			'only expose the children with explicit mention
			If exposeType = "selected" And Not callable.MetaData("_exposeToLua")
				If TMethod(callable)
					TLogger.Log("TLuaEngine", "[Engine " + id + "] Object "+typeId.name()+" does not expose method ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				Else
					TLogger.Log("TLuaEngine", "[Engine " + id + "] Object "+typeId.name()+" does not expose function ~q" + ident+"~q. Access Failed.", LOG_ERROR)
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
			?not bmxng
			If _constant.MetaData("_private")
			?bmxng
			If _constant.HasMetaData("_private")
			?
				TLogger.Log("TLuaEngine", "[Engine " + id + "] Object "+typeId.name()+" does not expose constant ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				Return False
			EndIf
			'only expose the children with explicit mention
			If exposeType = "selected" And Not _constant.MetaData("_exposeToLua")
				TLogger.Log("TLuaEngine", "[Engine " + id + "] Object "+typeId.name()+" does not expose constant ~q" + ident+"~q. Access Failed.", LOG_ERROR)
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
			?not bmxng
			If fld.MetaData("_private")
			?bmxng
			If fld.HasMetaData("_private")
			?
				TLogger.Log("TLuaEngine", "[Engine " + id + "] Object "+typeId.name()+" does not expose field ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				Return False
			EndIf
			If exposeType = "selected" And Not fld.MetaData("_exposeToLua")
				TLogger.Log("TLuaEngine", "[Engine " + id + "] Object "+typeId.name()+" does not expose field ~q" + ident+"~q. Access Failed.", LOG_ERROR)
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


		TLogger.Log("TLuaEngine", "[Engine " + id + "] Object "+typeId.name()+" does not have a property called ~q" + ident+"~q.", LOG_ERROR)
		Return False
	End Method


	Method CompareObjects:Int()
		Local obj1:Object, obj2:Object

		If lua_isnil(getLuaState(), -1)
			TLogger.Log("TLuaEngine", "[Engine " + id + "] CompareObjects: param #1 is nil.", LOG_DEBUG)
		Else
			obj1 = lua_unboxobject(getLuaState(), -1)
		EndIf
		If lua_isnil(getLuaState(), 1)
			TLogger.Log("TLuaEngine", "[Engine " + id + "] CompareObjects: param #2 is nil.", LOG_DEBUG)
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
			TLogger.Log("TLuaEngine", "[Engine " + id + "] Arrays are not supported - array type: " + typeId.name() + ".", LOG_ERROR)
			'array index is
			'print lua_tostring(getLuaState(), 2)
			'array value is
			'print lua_tostring(getLuaState(), 3)
			Return True
		EndIf

		'only expose if type set to get exposed
		If Not typeId.MetaData("_exposeToLua")
			TLogger.Log("TLuaEngine", "[Engine " + id + "] Type " + typeId.name() + " not exposed to Lua.", LOG_ERROR)
		EndIf
		Local exposeType:String = typeId.MetaData("_exposeToLua")


		Local fld:TField=typeId.FindField(ident)
		If fld
			'PRIVATE...do not allow write to  private functions/methods
			'check could be removed if performance critical
			?not bmxng
			If fld.MetaData("_private") Then Return True
			?bmxng
			If fld.HasMetaData("_private") Then Return True
			?
			'only set values of children with explicit mention
			If exposeType = "selected" And Not fld.MetaData("_exposeToLua") Then Return True
			If fld.MetaData("_exposeToLua")<>"rw"
				TLogger.Log("TLuaEngine", "[Engine " + id + "] Object property "+typeId.name()+"."+ident+" is read-only.", LOG_ERROR)
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
						fld.SetByte(obj, 0:Byte)
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
		Return TLuaEngine.CompareObjectsObject(fromLuaState)
	End Function

	Function Invoke:Int(fromLuaState:Byte Ptr)
		Local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)
		if not engine then return False
		Local result:Int = engine._Invoke()
		Return result
	End Function
	'====================================


	Method _Invoke:Int()
		Local obj:Object = lua_unboxobject(getLuaState(), LUA_GLOBALSINDEX - 1)
		Local funcOrMeth:TMember = TMember(lua_tolightobject(getLuaState(), LUA_GLOBALSINDEX - 2))
		If Not TFunction(funcOrMeth) And Not TMethod(funcOrMeth) 
			TLogger.Log("LuaEngine", "[Engine " + id + "] _Invoke() calling failed. No function/method given.", LOG_ERROR)
			Return False
		EndIf
		If Not obj 
			TLogger.Log("LuaEngine", "[Engine " + id + "] _Invoke() calling ~q" + funcOrMeth.name() + "()~q failed. No or invalid parent given.", LOG_ERROR)
			Return False
		EndIf
		Local func:TFunction = TFunction(funcOrMeth)
		Local mth:TMethod = TMethod(funcOrMeth)
		Local argTypes:TTypeId[]
		If func Then argTypes = func.ArgTypes()
		If mth Then argTypes = mth.ArgTypes()
		Local args:Object[argTypes.length]
		Local objType:TTypeID = TTypeID.ForObject(obj)

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
		Local passedArgumentCount:Int = lua_gettop(getLuaState())

		'Called as method or function?
		'-----------------------------
		'ignore first parameter?
		'(in case of calling from Lua as "method": TVT:GetXYZ() the first
		' parameter will be the "TVT" instance)
		Local isLuaMethodCall:Int = False
		if passedArgumentCount > 0
			local paramObj:object
			if lua_isnil(getLuaState(), 1)
				paramObj = null
			elseif lua_isuserdata(getLuaState(), 1)
				paramObj = lua_unboxobject(getLuaState(), 1)
			EndIf
		
			'first passed parameter is the same as the parent of the called
			'method/function? Might be a lua method call
			if paramObj = obj
				if passedArgumentCount = args.length + 1
					isLuaMethodCall = True
				EndIf
				'Maybe first param was forgotten but has to be of same
				'type as instance?
				'BlitzMax: Type TTest; Method MyMethod(t:TTest)
				'Lua: TVT:MyMethod()  -> blitzmax sees "TVT" as first arg
				'                        and could think it was called as
				'                        function with "TVT" as argument
				'Lua: TVT.MyMethod()  -> blitzmax sees no argument
				'                        it could correctly fail (wrong arg amount)
				If passedArgumentCount = args.length and argTypes[0] = objType
					isLuaMethodCall = False
					TLogger.Log("TLuaEngine", "[Engine " + id + "] _Invoke() calling ~q" + objType.name() + "." + funcOrMeth.name() + "()~q failed. Call is ambiguous (1st argument same type as instance. Either a method call or a function call with missing 1st parameter. Handled as Lua.Function() call.", LOG_DEBUG)
				EndIf
			endif
		Endif
		if isLuaMethodCall then passedArgumentCount :- 1
		

		If passedArgumentCount <> args.length
			TLogger.Log("TLuaEngine", "[Engine " + id + "] _Invoke() calling ~q" + objType.name() + "." + funcOrMeth.name() + "()~q failed. " + passedArgumentCount + " argument(s) passed but " + args.length+" argument(s) required.", LOG_ERROR)
			Return False
		EndIf


'debug information
rem
Local objName:String = "~qunknown type~q"
if objType Then objName = objType.Name()

if isLuaMethodCall
	print "[Engine " + id + "] _Invoke() Meth: " + objName + "."+funcOrMeth.name()
else
	print "[Engine " + id + "] _Invoke() Func: " + objName + "."+funcOrMeth.name()
endif
endrem

		'ignore first param for lua method calls
		Local luaArgsOffset:Int = 0
		if isLuaMethodCall then luaArgsOffset = 1

		Local invalidArgs:Int = 0
		For Local i:Int = 0 Until args.length
			Select argTypes[i]
				Case IntTypeId, ShortTypeId, ByteTypeId
					if lua_isboolean(getLuaState(), i + luaArgsOffset + 1)
						args[i] = String.FromInt(int(lua_toboolean(getLuaState(), i + luaArgsOffset + 1)))
					else
						?ptr64
							args[i] = String.FromLong(lua_tointeger(getLuaState(), i + luaArgsOffset + 1))
						?Not ptr64
							args[i] = String.FromInt(int(lua_tointeger(getLuaState(), i + luaArgsOffset + 1)))
						?
					endif
				Case LongTypeId
?not ptr64
Notify "Reflection with ~qlong~q-parameters is bugged. Do not use it in 32bit-builds!"
?
					if lua_isboolean(getLuaState(), i + luaArgsOffset + 1)
						args[i] = String.FromInt(int(lua_toboolean(getLuaState(), i + luaArgsOffset + 1)))
					else
						args[i] = String.FromLong(Long(lua_tonumber(getLuaState(), i + luaArgsOffset + 1)))
					endif
				Case FloatTypeId
					args[i] = String.FromFloat(Float(lua_tonumber(getLuaState(), i + luaArgsOffset + 1)))
				Case DoubleTypeId
?not ptr64
Notify "Reflection with ~qlong~q-parameters is bugged. Do not use it in 32bit-builds!"
?
					args[i] = String.FromDouble(lua_tonumber(getLuaState(), i + luaArgsOffset + 1))
				Case StringTypeId
					args[i] = lua_tostring(getLuaState(), i + luaArgsOffset + 1)
				Default
					local paramObj:object
					if lua_isnil(getLuaState(), i + luaArgsOffset + 1)
						paramObj = null
					elseif lua_isuserdata(getLuaState(), i + luaArgsOffset + 1)
						paramObj = lua_unboxobject(getLuaState(), i + luaArgsOffset + 1)
						Local paramObjType:TTypeID = TTypeID.ForObject(paramObj)
						'given param does not derive from requested param type (so incompatible)
						if not paramObjType or not paramObjType.ExtendsType(argTypes[i])
							TLogger.Log("TLuaEngine", "[Engine " + id + "] _Invoke() ~q" + objType.name() + "." + funcOrMeth.name()+"()~q - param #"+i+" is invalid (expected ~q"+argTypes[i].name()+"~q, received incompatible ~q"+TTypeID.ForObject(paramObj).name()+"~q).", LOG_DEBUG)
							invalidArgs :+ 1
							paramObj = Null
						endif
					else
						TLogger.Log("TLuaEngine", "[Engine " + id + "] _Invoke() ~q" + objType.name() + "." + funcOrMeth.name()+"()~q - param #"+i+" is invalid (expected ~q"+argTypes[i].name()+"~q, received no userdata obj).", LOG_DEBUG)
						invalidArgs :+ 1
						paramObj = null
					endif
					args[i] = paramObj
			End Select
		Next
		'stop execution if an argument did not fit
		if invalidArgs > 0
			TLogger.Log("TLuaEngine", "[Engine " + id + "] _Invoke() failed to call ~q" + objType.name() + "." + funcOrMeth.name() + "()~q. " + invalidArgs + " invalid argument(s) passed.", LOG_ERROR)
			Return False
		EndIf

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
			TLogger.Log("TLuaEngine", "[Engine " + id + "] CallLuaFunction(~q" + name + "~q) failed. Unknown function.", LOG_DEBUG)
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
		Local callResult:Int
		if debugCalls
			'stack pos for message handler
			Local stackPos:Int = lua_gettop(GetLuaState() ) - argCount
			'assign debug.traceback as error handler for the protected call
			lua_getglobal(GetLuaState(), "debug")
			lua_getfield(GetLuaState(), -1, "traceback")
			'remove "debug" table from stack
			lua_remove(GetLuaState(), -2)
			'move "traceback" before function and arguments
			lua_insert(GetLuaState(), stackPos)
			'call lua_pcall function with custom error/traceback handler
			callResult = lua_pcall(GetLuaState(), argCount, 1, stackPos)
			'remove custom error message/backtrace handler from stack
			lua_remove( GetLuaState(), stackPos )

			if callResult <> 0 Then DumpError("Runtime Error")
		Else
			'protected call?
			callResult = lua_pcall(getLuaState(), argCount, 1, 0) 
			'or unprotected call
			'lua_call(GetLuaState(), argCount, 1)
		EndIf

		If callResult = 0
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
