SuperStrict
Import Pub.Lua
Import Brl.Retro
'using custom to have support for const/function reflection
Import "external/reflectionExtended/reflection.bmx"
Import "base.util.logger.bmx"
'from maxlua, modified to define "THREADED"
Import "base.util.luaengine.c"

Extern
	Function lua_boxobject( L:Byte Ptr,obj:Object )
	Function lua_unboxobject:Object( L:Byte Ptr,index:Int)
	Function lua_pushlightobject( L:Byte Ptr,obj:Object )
	Function lua_tolightobject:Object( L:Byte Ptr,index:Int )
	Function lua_gcobject( L:Byte Ptr )
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
	Field _modulesToLoad:string[] = ["all"]
	'functions/calls getting "nil"ed before the script is run
	'eg. ["os"]
	Field _blacklistedFunctions:string[]

	'which elements can get read without "_exposeToLua" metadata?
	Field whiteListedTypes:TList = CreateList()
	Field whiteListCreated:int = False


	Function Create:TLuaEngine(source:String)
		Local obj:TLuaEngine = New TLuaEngine.SetSource(source)
		'add here so during "RegisterToLua" code could run already
		list.addLast(obj)

		'init fenv and register self
		obj.RegisterToLua()
		obj.lastID :+1
		obj.id = obj.lastID

		obj.GenerateWhiteList()

		Return obj
	End Function


	Method GenerateWhiteList:int()
		if whiteListCreated then return True

		whiteListedTypes.AddLast("tlist")
		whiteListedTypes.AddLast("tmap")

		whiteListCreated = True
		return True
	End Method
	

	Method Delete()
		luaL_unref(getLuaState(), LUA_REGISTRYINDEX, _functionEnvironmentRef)
		luaL_unref(getLuaState(), LUA_REGISTRYINDEX, _chunk)
	End Method


	Function FindEngine:TLuaEngine(LuaState:Byte Ptr)
		For Local engine:TLuaEngine = EachIn TLuaEngine.list
			If engine._luaState = LuaState then Return engine
		Next
		TLogger.log("TLuaEngine", "FindEngine(): engine not found.", LOG_ERROR)
		Return Null
	End Function


	'register libraries to lua
	'available libs:
	'"base" = luaopen_base       "debug" = luaopen_debug
	'"io" = luaopen_io           "math" = luaopen_math
	'"os" = luaopen_os           "package" = luaopen_package
	'"string"= luaopen_string    "table" = luaopen_table
	Function RegisterLibraries:int(lua_state:Byte Ptr, libnames:string[])
		if not libnames then libnames = ["all"]
		
		For local lib:string = eachin libnames
			Select lib.toLower()
				'registers all libs
				case "all"      LuaL_openlibs(lua_state)
				                return True
				'register single libs
				case "base"     lua_register(lua_state, lib, luaopen_base)
				case "debug"    lua_register(lua_state, lib, luaopen_debug)
				case "io"       lua_register(lua_state, lib, luaopen_io)
				case "math"     lua_register(lua_state, lib, luaopen_math)
				case "os"       lua_register(lua_state, lib, luaopen_os)
				case "package"  lua_register(lua_state, lib, luaopen_package)
				case "string"   lua_register(lua_state, lib, luaopen_string)
				case "table"    lua_register(lua_state, lib, luaopen_table)
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


	Method SetSource:TLuaEngine(source:String)
		_source = source
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

		'BlackListLuaModules()

		'set fenv metatable
		lua_pushvalue(getLuaState(), -1)
		lua_setmetatable(getLuaState(), -2)

		'ready!
		lua_setfenv(getLuaState(), -2)
		If lua_pcall(getLuaState(), 0, 0, 0 ) Then DumpError()
	End Method


	Method BlackListFunctions()
		for local entry:string = eachin _blacklistedFunctions
			lua_pushnil(getLuaState())
			lua_setglobal(getLuaState(), entry)
		next
	endmethod


	Method DumpError()
		TLogger.log("TLuaEngine", "#### ERROR #######################", LOG_ERROR)
		TLogger.log("TLuaEngine", "Engine: " + id, LOG_ERROR)
		Tlogger.log("TLuaEngine", lua_tostring( getLuaState(), -1 ), LOG_ERROR)
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
		Local size:Int = typeId.ArrayLength(obj)

		lua_createtable(getLuaState(), size + 1, 0)

		'lua is not zero based as BlitzMax is... so we have to add one
		'entry at the first pos
		lua_pushinteger(getLuaState(), 0)
		lua_pushinteger(getLuaState(), -1)
		lua_settable(getLuaState(), -3)


		For Local i:Int = 0 until size
			' the index +1 as not zerobased
			lua_pushinteger(getLuaState(), i+1)

			Select typeId.ElementType()
				Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId
					lua_pushinteger(getLuaState(), typeId.GetArrayElement(obj, i).ToString().ToInt())
				Case FloatTypeId
					lua_pushnumber(getLuaState(), typeId.GetArrayElement(obj, i).ToString().ToFloat())
				Case DoubleTypeId
					lua_pushnumber(getLuaState(), typeId.GetArrayElement(obj, i).ToString().ToDouble())
				Case StringTypeId
					Local s:String = typeId.GetArrayElement(obj, i).ToString()
					lua_pushlstring(getLuaState(), s, s.length)
				Case ArrayTypeId
					self.lua_pushArray(typeId.GetArrayElement(obj, i))
				'for everything else, we just push the object...
				Default
					self.lua_pushObject(typeId.GetArrayElement(obj, i))
			End Select

			lua_settable(getLuaState(), -3)
		Next
	End Method


	'calls getobjmetatable
	Method lua_pushobject(obj:Object)
		'convert BlitzMax "null"-objects to lua compatible "nil" values
		If obj = null
			lua_pushnil(getLuaState())
		Else
			lua_boxobject(getLuaState(), obj)
			lua_rawgeti(getLuaState(), LUA_REGISTRYINDEX, getObjMetaTable())
			lua_setmetatable(getLuaState(),-2)
		Endif
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
			_objMetaTable = luaL_ref(getLuaState(), LUA_REGISTRYINDEX)

			_initDone = True
		EndIf
		Return _objMetaTable
	End Method

	'adding a new method/field/func to lua
	Method Index:Int( )
		Local obj:Object = lua_unboxobject(getLuaState(), 1)
		Local typeId:TTypeId = TTypeId.ForObject(obj)
		Local ident:String = lua_tostring(getLuaState(), 2)

		'by default allow read access to lists/maps ?!
		local whiteListedType:int = whiteListedTypes.contains(typeId.name().toLower())

		'only expose if type ("parent") is set to get exposed
		if not whiteListedType and not typeId.MetaData("_exposeToLua") then return False
		local exposeType:string = typeId.MetaData("_exposeToLua")

		'===== SKIP PRIVATE THINGS =====
		'each variable/function with an underscore is private
		'eg.: function _myPrivateFunction
		'eg.: field _myPrivateField
		'
		'but lua needs access to global: _G
		if Chr( ident[0] ) =  "_" and ident <> "_G" then return False

		'===== CHECK PUSHED OBJECT IS A METHOD =====
		Local mth:TMethod = typeId.FindMethod(ident)
		'thing we have to push is a method
		If mth
			'PRIVATE...do not add private functions/methods
			if mth.MetaData("_private")
				TLogger.log("TLuaEngine", "Object "+typeId.name()+" does not expose method ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				return False
			endif
			'only expose the children with explicit mention
			if exposeType = "selected" AND not mth.MetaData("_exposeToLua")
				TLogger.log("TLuaEngine", "Object "+typeId.name()+" does not expose method ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				return False
			endif

			lua_pushvalue(getLuaState(), 1)
			lua_pushlightobject(getLuaState(), mth)
			lua_pushcclosure(getLuaState(), Invoke, 2)
			Return True
		EndIf

rem
		'===== CHECK PUSHED OBJECT IS A FUNCTION =====
		Local _function:TFunction = typeId.FindFunction( ident )
		If _function
			'PRIVATE...do not add private functions/methods
			if _function.MetaData("_private")
				TLogger.log("TLuaEngine", "Object "+typeId.name()+" does not expose function ~q" + ident+"~q. Access Failed.", LOG_ERROR )
				return false
			endif
			'only expose the children with explicit mention
			if exposeType = "selected" AND not _function.MetaData("_exposeToLua")
				TLogger.log("TLuaEngine", "Object "+typeId.name()+" does not expose function ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				return false
			endif

			lua_pushvalue( getLuaState(),1 )
			lua_pushlightobject( getLuaState(), _function )
			lua_pushcclosure( getLuaState(),Invoke,2 )
			Return True
		EndIf
endrem

		'===== CHECK PUSHED OBJECT IS A CONSTANT =====
		Local _constant:TConstant = typeId.FindConstant(ident)
		If _constant
			'PRIVATE...do not add private functions/methods
			if _constant.MetaData("_private")
				TLogger.log("TLuaEngine", "Object "+typeId.name()+" does not expose constant ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				return False
			endif
			'only expose the children with explicit mention
			if exposeType = "selected" AND not _constant.MetaData("_exposeToLua")
				TLogger.log("TLuaEngine", "Object "+typeId.name()+" does not expose constant ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				return False
			endif

			Select _constant.TypeId() ' BaH - added more types
				Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId
					lua_pushinteger(getLuaState(), _constant.GetInt())
				Case FloatTypeId
					lua_pushnumber(getLuaState(), _constant.GetFloat())
				Case DoubleTypeId
					lua_pushnumber(getLuaState(), _constant.GetDouble())
				Case StringTypeId
					Local t:String = _constant.GetString()
					lua_pushlstring(getLuaState(), t, t.length)
			End Select
			return TRUE
		endif


		'===== CHECK PUSHED OBJECT IS A FIELD =====
		Local fld:TField = typeId.FindField(ident)
		If fld
			'PRIVATE...do not add private functions/methods
			'SELECTED...only expose the children with explicit mention
			if fld.MetaData("_private")
				TLogger.log("TLuaEngine", "Object "+typeId.name()+" does not expose field ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				return False
			endif
			if exposeType = "selected" AND not fld.MetaData("_exposeToLua")
				TLogger.log("TLuaEngine", "Object "+typeId.name()+" does not expose field ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				return False
			endif

			Select fld.TypeId() ' BaH - added more types
				Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId
					lua_pushinteger(getLuaState(), fld.GetInt(obj))
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
					lua_pushobject(fld.Get(obj))
			End Select
			Return True
		endif


		TLogger.log("TLuaEngine", "Object "+typeId.name()+" does not have a property called ~q" + ident+"~q.", LOG_ERROR)
		return FALSE
	End Method


	Method NewIndex:Int( )
		Local obj:Object = lua_unboxobject(getLuaState(), 1)
		Local typeId:TTypeId = TTypeId.ForObject(obj)

		Local ident:String = lua_tostring(getLuaState(), 2)
		Local mth:TMethod = typeId.FindMethod(ident)
		If mth Then Throw "newIndex ERROR"

		'I do not know how to handle arrays properly (needs metatables
		'and custom userdata)
		if typeId.name().contains("[]")
			TLogger.log("TLuaEngine", "Arrays are not supported - array type: " + typeId.name() + ".", LOG_ERROR)
			'array index is
			'print lua_tostring(getLuaState(), 2)
			'array value is
			'print lua_tostring(getLuaState(), 3)
			return True
		endif

		'only expose if type set to get exposed
		if not typeId.MetaData("_exposeToLua")
			TLogger.log("TLuaEngine", "Type " + typeId.name() + " not exposed to Lua.", LOG_ERROR)
		endif
		local exposeType:string = typeId.MetaData("_exposeToLua")


		Local fld:TField=typeId.FindField(ident)
		If fld
			'PRIVATE...do not allow write to  private functions/methods
			'check could be removed if performance critical
			if fld.MetaData("_private") then return True
			'only set values of children with explicit mention
			if exposeType = "selected" AND not fld.MetaData("_exposeToLua") then return True
			if fld.MetaData("_exposeToLua")<>"rw"
				TLogger.log("TLuaEngine", "Object property "+typeId.name()+"."+ident+" is read-only.", LOG_ERROR)
				return TRUE
			endif

			If lua_isnil(getLuaState(), 3)
				Select fld.TypeId()
					Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId, FloatTypeId, DoubleTypeId, StringTypeId
						'SetInt/SetFloat/...all convert to a string
						'"null" is 0/0.0/"" for primitive types in BlitzMax
						fld.SetString(obj, "")
					Default
						fld.Set(obj, null)
				End Select
			else
				Select fld.TypeId()
					Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId
						fld.SetInt(obj, lua_tointeger(getLuaState(), 3))
					Case FloatTypeId
						fld.SetFloat(obj, lua_tonumber(getLuaState(), 3))
					Case DoubleTypeId
						fld.SetDouble(obj, lua_tonumber(getLuaState(), 3))
					Case StringTypeId
						fld.SetString(obj, lua_tostring(getLuaState(), 3))
					Default
						fld.Set(obj, lua_unboxobject(getLuaState(), 3))
				End Select
			endif
			Return True
		EndIf
		TLogger.log("TLuaEngine", "newindex: ident not found " + ident + ".", LOG_ERROR)
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
		If engine And engine.NewIndex() Then Return True
		Throw "newindexobject ERROR"
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

	Function NewIndexSelf(fromLuaState:Byte Ptr)
		'local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)
		lua_rawset(fromLuaState, 1)
	End Function

	Function Invoke:Int(fromLuaState:Byte Ptr)
		Local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)
		Return engine._Invoke()
	End Function
	'====================================


	Method _Invoke:Int()
		Local obj:Object = lua_unboxobject(getLuaState(), LUA_GLOBALSINDEX - 1)
		Local meth:TMethod = TMethod(lua_tolightobject(getLuaState(), LUA_GLOBALSINDEX - 2))
		Local tys:TTypeId[]	= meth.ArgTypes()
		Local args:Object[tys.length]

		For Local i:Int = 0 Until args.length
			Select tys[i]
				Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId
					args[i] = String.FromInt(lua_tointeger(getLuaState(), i + 1))
				Case FloatTypeId
					args[i] = String.FromFloat(lua_tonumber(getLuaState(), i + 1))
				Case DoubleTypeId
					args[i] = String.FromDouble(lua_tonumber(getLuaState(), i + 1))
				Case StringTypeId
					args[i] = lua_tostring(getLuaState(), i + 1)
				Default
					args[i] = lua_unboxobject(getLuaState(), i + 1)
			End Select
		Next
		Local t:Object = meth.Invoke(obj, args)
		local typeId:TTypeID = meth.TypeId()
		if object[](t).length > 0 then typeId = ArrayTypeId

		Select typeId
			Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId
				lua_pushinteger(getLuaState(), t.ToString().ToInt())
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
				lua_pushobject(t)
		End Select
		Return True
	End Method

	'===== END CODE FROM MAXLUA ====


	Method CallLuaFunction:Object(name:String, args:Object[] = Null)
		'push fenv
		lua_rawgeti(getLuaState(), LUA_REGISTRYINDEX, _functionEnvironmentRef)

		lua_getfield(getLuaState(), -1, name)
		If lua_isnil(getLuaState(), -1)
			lua_pop(getLuaState(), 2)
			Return Null
		EndIf
		For Local i:Int = 0 Until args.length
			Local typeId:TTypeId = TTypeId.ForObject(args[i])
			Select typeId
				Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId
					lua_pushinteger(getLuaState(), args[i].ToString().ToInt())
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
					Self.lua_pushobject(args[i])
			End Select
		Next
		If lua_pcall(getLuaState(), args.length, 1, 0) Then DumpError()

		Local ret:Object
		If Not lua_isnil(getLuaState(), -1) Then ret = lua_tostring(getLuaState(), -1)

		'pop the result
		lua_pop(getLuaState(), 1)

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