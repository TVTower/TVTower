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

	Copyright (C) 2002-2025 Ronny Otto, digidea.de

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
Import "base.util.luaengine.c"
Import "base.util.logger.bmx"

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
End Extern



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


	Global lastID:Int = 0
	Global _enginesList:TList = CreateList()
	Global _enginesListMutex:TMutex = CreateMutex()



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
		LockMutex(_enginesListMutex)
		_enginesList.AddLast(engine)
		UnlockMutex(_enginesListMutex)
	End Function
	

	Function RemoveEngine(engine:TLuaEngine)
		LockMutex(_enginesListMutex)
		_enginesList.Remove(engine)
		UnlockMutex(_enginesListMutex)
	End Function


	'find a previously added engine by a given lua state pointer
	Function FindEngine:TLuaEngine(LuaState:Byte Ptr)
		LockMutex(_enginesListMutex)
		Local result:TLuaEngine
		For Local engine:TLuaEngine = EachIn _enginesList
			If engine._luaState = LuaState 
				result = engine
				exit
			EndIf
		Next
		UnLockMutex(_enginesListMutex)

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

		'prepend URI as CURRENT_WORKING_DIR global
		_currentWorkingDirectory = ExtractDir(sourceFile)
		_sourceFile = sourceFile

		'prepend cwd as a single line so error offsets are -1
		Local cwdLine:String = "--" + _currentWorkingDirectory + "       ; CURRENT_WORKING_DIR = ~q" + _currentWorkingDirectory + "~q; " + "package.path = CURRENT_WORKING_DIR .. '/?.lua;' .. package.path .. ';'~n"
		
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
	
	
	'=== LUA BLITZMAX COUPLING ===
	
	Function _HandleIndex:Int(luaState:Byte Ptr)
		' called as soon as Lua requests a property or method of an object
		' which it does not know about (ex. "myobject:themethod()"
		Local engine:TLuaEngine = TLuaEngine.FindEngine(luaState)

		' Defer to engine instance method
		' Leave the result on the stack (or nil if not found)
		Return engine.HandleIndex()
	End Function


	Function _HandleSuper:Int(luaState:Byte Ptr)
		' called as soon as Lua requests a property or method of an object
		' which it does not know about (ex. "myobject:themethod()"
	print "DDD _HandleSuper"
		Local engine:TLuaEngine = TLuaEngine.FindEngine(luaState)

		' Lua will push nil if the global table doesn't resolve the key
		' Leave the result on the stack (or nil if not found)
		Return 1
	End Function


	Function _HandleNewIndex:Int(luaState:Byte Ptr)
		' called as soon as Lua wants to write to a field of an object
		Local engine:TLuaEngine = TLuaEngine.FindEngine(luaState)

		' Defer to engine instance method
		' Leave the result on the stack (or nil if not found)
		Return engine.HandleNewIndex()
	End Function


	Function _HandleInvoke:Int(luaState:Byte Ptr)
		' called as soon as Lua wants to call a blitzmax method/function
		Local engine:TLuaEngine = FindEngine(luaState)
		if not engine then return False
		Return engine.HandleInvoke()
	End Function


	Function _HandleEQ:Int(luaState:Byte Ptr)
		' called as soon as Lua wants to compare two (blitzmax) objects
		Local engine:TLuaEngine = TLuaEngine.FindEngine(luaState)
		If engine Then Return engine.HandleEQ()
	End Function


	'Implementation with the engine as context
	
	Method HandleIndex:Int()
		'pull blitzmax object (parent of the method)
		Local obj:Object = lua_unboxobject(_luaState, 1, _objMetaTable)

		' Check if the object was valid before proceeding
		If Not obj
			Local ident:String = lua_tobbstring(_luaState, 2)
			' Log error if the object is invalid
			TLogger.Log("TLuaEngine", "[Engine " + id + "] Attempted to access ~q"+ident+"~q (method or property) of an invalid object. Object not exposed? Object name wrong? Lua is case-sensitive!", LOG_ERROR)
			Return 0
		EndIf

		Local typeId:TTypeId = TTypeId.ForObject(obj)
		Local objTypeName:String = typeId.name()

		'=== READ ACCESS ? ===
'TODO: Alles cachen (_knownExposableTypes:TStringMap ...) ?
		Local whiteListedType:Int = _whiteListedTypes.Contains(objTypeName)
		Local exposeType:String
		if not whiteListedType
			exposeType = typeId.MetaData("_exposeToLua")

			'whitelist the type if set to expose everything not just
			'"selected"
			if exposeType <> "selected"
				_whiteListedTypes.Insert(objTypeName, "" )
			endif
		endif

		'only expose if type ("parent") is set to get exposed
		If Not whiteListedType And Not exposeType 
			TLogger.Log("TLuaEngine", "[Engine " + id + "] Object "+objTypeName+" is not whitelisted or marked to get exposed to lua. Access Failed.", LOG_ERROR)
			Return False
		EndIf

		Local ident:String = lua_tobbstring(_luaState, 2)

		'=== SKIP PRIVATE THINGS ===
		'each variable/function with an underscore is private
		'eg.: function _myPrivateFunction
		'eg.: field _myPrivateField
		'
		'but lua needs access to global: _G
'		If ident[0] =  Asc("_") And ident <> "_G" Then Return False


		'=== CHECK PUSHED OBJECT IS A METHOD or FUNCTION ===
		Local callable:TMember = typeId.FindMethod(ident)
		If Not callable Then callable = typeId.FindFunction(ident)

		'thing we have to push is a method/function
		If callable
			'PRIVATE...do not add private functions/methods
			If callable.HasMetaData("_private")
				If TMethod(callable)
					TLogger.Log("TLuaEngine", "[Engine " + id + "] Object "+objTypeName+" does not expose method ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				Else
					TLogger.Log("TLuaEngine", "[Engine " + id + "] Object "+objTypeName+" does not expose function ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				EndIf
				Return False
			EndIf
			'only expose the children with explicit mention
			If exposeType = "selected" And Not callable.MetaData("_exposeToLua")
				If TMethod(callable)
					TLogger.Log("TLuaEngine", "[Engine " + id + "] Object "+objTypeName+" does not expose method ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				Else
					TLogger.Log("TLuaEngine", "[Engine " + id + "] Object "+objTypeName+" does not expose function ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				EndIf
				Return False
			EndIf
			lua_pushvalue(_luaState, 1)
			lua_pushlightobject(_luaState, callable)
			lua_pushcclosure(_luaState, _HandleInvoke, 2)
			Return True
		EndIf


		'===== CHECK PUSHED OBJECT IS A FIELD / CONSTANT =====
		Local fld:TField = typeId.FindField(ident)
		If fld
			'PRIVATE...do not add private fields
			'SELECTED...only expose the fields with explicit mention
			If fld.HasMetaData("_private") or (exposeType = "selected" And Not fld.MetaData("_exposeToLua"))
				TLogger.Log("TLuaEngine", "[Engine " + id + "] Object "+objTypeName+" does not expose field ~q" + ident + "~q. Access Failed.", LOG_ERROR)
				Return False
			EndIf

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
			Return True
		EndIf


		'===== CHECK PUSHED OBJECT IS A CONSTANT =====
		Local constant:TConstant = typeId.FindConstant(ident)
		If constant
			'PRIVATE...do not add private fields
			'SELECTED...only expose the fields with explicit mention
			If constant.HasMetaData("_private") or (exposeType = "selected" And Not constant.MetaData("_exposeToLua"))
				TLogger.Log("TLuaEngine", "[Engine " + id + "] Object "+objTypeName+" does not expose constant ~q" + ident + "~q. Access Failed.", LOG_ERROR)
				Return False
			EndIf

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
			Return True
		EndIf

		TLogger.Log("TLuaEngine", "[Engine " + id + "] Object "+objTypeName+" does not have a property called ~q" + ident+"~q.", LOG_ERROR)
		Return False
	End Method



	Method HandleNewIndex:Int( )
		Local obj:Object = lua_unboxobject(_luaState, 1, _objMetaTable)
		Local passedArgumentCount:Int = lua_gettop(_luaState)
		Local ident:String = lua_tobbstring(_luaState, 2)

		'=== CHECK OBJ / PROPERTY AND PRIVACY ===

		' Check if the object was valid before proceeding
		If Not obj
			' remove unprocessed arguments
			lua_pop(_luaState, passedArgumentCount)
			' Log error if the object is invalid
			TLogger.Log("TLuaEngine", "[Engine " + id + "] Attempted to set field ~q"+ident+"~q of an invalid object. Object not exposed?", LOG_ERROR)
			Return 0
		EndIf


		Local typeId:TTypeId = TTypeId.ForObject(obj)

		'only expose if type set to get exposed
		Local exposeType:String = typeId.MetaData("_exposeToLua")
		If not exposeType
			TLogger.Log("TLuaEngine", "[Engine " + id + "] Type " + typeId.name() + " not exposed to Lua.", LOG_ERROR)
		EndIf

		'I do not know how to handle arrays properly (needs metatables
		'and custom userdata)
		If typeId.name().contains("[]")
			TLogger.Log("TLuaEngine", "[Engine " + id + "] Arrays are not supported - array type: " + typeId.name() + ".", LOG_ERROR)
			'array index is
			'print lua_tobbstring(_luaState, 2)
			'array value is
			'print lua_tobbstring(_luaState, 3)
			Return True
		EndIf


		Local fld:TField=typeId.FindField(ident)
		If Not fld
			' remove unprocessed arguments
			lua_pop(_luaState, passedArgumentCount)
			If exposeType = "selected" 
				TLogger.Log("TLuaEngine", "[Engine " + id + "] Attempted to set unknown field ~q"+ident+"~q. Field not exposed with {_exposeToLua=~qrw~q} ?", LOG_ERROR)
			Else
				TLogger.Log("TLuaEngine", "[Engine " + id + "] Attempted to set unknown field ~q"+ident+"~q.", LOG_ERROR)
			EndIf
		EndIf
		
		
		'=== SET FIELD VALUE ===

		If fld
			'PRIVATE...do not allow write to  private functions/methods
			'check could be removed if performance critical
			If fld.HasMetaData("_private") Then Return True

			'only set values of children with explicit mention
			If exposeType = "selected" And Not fld.MetaData("_exposeToLua") Then Return True
			If fld.MetaData("_exposeToLua")<>"rw"
				TLogger.Log("TLuaEngine", "[Engine " + id + "] Object property "+typeId.name()+"."+ident+" is read-only. Forgot to mark  {_exposeToLua=~qrw~q} ?", LOG_ERROR)
				Return True
			EndIf

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
			Return True
		EndIf
	End Method



	Method HandleInvoke:Int()
		Local obj:Object = lua_unboxobject(_luaState, LUA_GLOBALSINDEX - 1, _objMetaTable)
		Local passedArgumentCount:Int = lua_gettop(_luaState)

		' Check if the object is still valid
		If Not obj
			' remove unprocessed arguments
			lua_pop(_luaState, passedArgumentCount)
			TLogger.Log("TLuaEngine", "[Engine " + id + "] Attempted to call method or read a property of an invalid object. Object garbage collected?", LOG_ERROR)

			Return 0
		EndIf

		Local objType:TTypeID = TTypeID.ForObject(obj)
		Local funcOrMeth:TMember = TMember(lua_tolightobject(_luaState, LUA_GLOBALSINDEX - 2))
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
			local paramObj:object
			if lua_isnil(_luaState, 1)
				paramObj = null
			elseif lua_isuserdata(_luaState, 1)
				paramObj = lua_unboxobject(_luaState, 1, _objMetaTable)
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

		'ignore first param for lua method calls
		Local luaArgsOffset:Int = 0
		if isLuaMethodCall then luaArgsOffset = 1

		Local invalidArgs:Int = 0
		For Local i:Int = 0 Until args.length
			Local luaIndex:Int = i + luaArgsOffset + 1  ' Precompute Lua stack index

			Select argTypes[i]
				Case IntTypeId, ShortTypeId, ByteTypeId
					if lua_isboolean(_luaState, luaIndex)
						args[i] = String.FromInt(int(lua_toboolean(_luaState, luaIndex)))
					else
						?ptr64
							args[i] = String.FromLong(lua_tointeger(_luaState, luaIndex))
						?Not ptr64
							args[i] = String.FromInt(int(lua_tointeger(_luaState, luaIndex)))
						?
					endif
				Case LongTypeId
					?not ptr64
					Notify "Reflection with ~qlong~q-parameters is bugged. Do not use it in 32bit-builds!"
					?
					if lua_isboolean(_luaState, luaIndex)
						args[i] = String.FromInt(int(lua_toboolean(_luaState, luaIndex)))
					else
						args[i] = String.FromLong(Long(lua_tonumber(_luaState, i + luaIndex)))
					endif
				Case FloatTypeId
					args[i] = String.FromFloat(Float(lua_tonumber(_luaState, luaIndex)))
				Case DoubleTypeId
					?not ptr64
					Notify "Reflection with ~qlong~q-parameters is bugged. Do not use it in 32bit-builds!"
					?
					args[i] = String.FromDouble(lua_tonumber(_luaState, luaIndex))
				Case StringTypeId
					args[i] = lua_tobbstring(_luaState, luaIndex)
				Default
					local paramObj:object
					if lua_isnil(_luaState, luaIndex)
						paramObj = null
					elseif lua_isuserdata(_luaState, luaIndex)
						paramObj = lua_unboxobject(_luaState, luaIndex, _objMetaTable)
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
		If func Then t = func.Invoke(args)
		If mth Then t = mth.Invoke(obj, args)
		Local typeId:TTypeId = funcOrMeth.TypeID().ReturnType()

		If Object[](t).length > 0 Then typeId = ArrayTypeId

		Select typeId
			Case IntTypeId, ShortTypeId, ByteTypeId
				lua_pushinteger(_luaState, t.ToString().ToInt())
'				lua_pushnumber(_luaState, t.ToString().ToLong())
			Case LongTypeId
				lua_pushnumber(_luaState, t.ToString().ToLong())
			Case FloatTypeId
				lua_pushnumber(_luaState, t.ToString().ToFloat())
			Case DoubleTypeId
				lua_pushnumber(_luaState, t.ToString().ToDouble())
			Case StringTypeId
				Local s:String = t.ToString()
				lua_pushbbstring(_luaState, s)
			Case ArrayTypeId
				lua_pushArray(_luaState, t, _objMetaTable)
			Default
				If typeId And typeId.ExtendsType(ArrayTypeId)
					lua_pushArray(_luaState, t, _objMetaTable)
				Else
					lua_pushobject(_luaState, t, _objMetaTable)
				EndIf
		End Select
		Return True
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

		Return True
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
				Local typeId:TTypeId = TTypeId.ForObject(args[i])

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
			lua_pop(_luaState, 1)  ' Pop the error message
   			'TODO print error
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
	Function lua_pusharray:Int(luaState:Byte Ptr, arr:Object, _objMetaTable:Int)
		Local typeId:TTypeId = TTypeId.ForObject(arr)
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
