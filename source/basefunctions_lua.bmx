SuperStrict
Import Pub.Lua
Import BRL.Reflection
Import brl.retro
'from maxlua
?threaded
Import "basefunctions_lua_threaded.c"
?not threaded
Import "basefunctions_lua.c"
?
Extern
	Function lua_boxobject( L:Byte Ptr,obj:Object )
	Function lua_unboxobject:Object( L:Byte Ptr,index:Int)
	Function lua_pushlightobject( L:Byte Ptr,obj:Object )
	Function lua_tolightobject:Object( L:Byte Ptr,index:Int )
	Function lua_gcobject( L:Byte Ptr )
End Extern
'end from maxlua


Type TLuaEngine
	Global list:TList	= CreateList()
	Global lastID:Int = 0
	Field id:Int = 0

	Field _luaState:Byte Ptr		'Pointer to current lua environment
	Field _source:String	= ""	'current code
	Field _chunk:Int		= 0		'current code loaded as chunk
	Field _initDone:Int		= 0		'meta table set up finished?
	Field _objMetaTable:Int			'for GC ... from MaxLua
	Field _fenv:Int					'we store other objects in our metatable - we are responsible for them
									'fenv should be known from Lua itself

	Function Create:TLuaEngine( source:String )
		Local obj:TLuaEngine = New TLuaEngine.SetSource( source )
		'init fenv and register self
		obj.RegisterToLua()
		obj.lastID :+1
		obj.id = obj.lastID

		Self.list.addLast(obj)
		Return obj
	End Function

	Method Delete()
		luaL_unref( getLuaState(),LUA_REGISTRYINDEX, _fenv )
		luaL_unref( getLuaState(),LUA_REGISTRYINDEX, _chunk )
	End Method


	Function FindEngine:TLuaEngine(LuaState:Byte Ptr)
		'local num:int = 1
		For Local engine:TLuaEngine = EachIn TLuaEngine.list
			If engine._luaState = LuaState
				'print "engine number "+num
				Return engine
			EndIf
			'num:+1
		Next
		Print "engine not found"
		Return Null
	End Function

	Method getLuaState:Byte Ptr()
		If Not Self._luaState
			Self._luaState=luaL_newstate()
			luaL_openlibs Self._luaState
		EndIf
		Return Self._luaState
	End Method

	Method getSource:String()
		Return _source
	End Method

	Method SetSource:TLuaEngine( source:String )
		_source=source
		If _chunk
			luaL_unref( getLuaState(),LUA_REGISTRYINDEX,_chunk )
			_chunk=0
		EndIf

		Self.RegisterToLua()

		Return Self
	End Method

	'we are parent of other registered objects
	Method RegisterToLua:Int()
		'push class block
		If Not lua_pushchunk() Then Return Null

		'create fenv table
		lua_newtable( getLuaState() )

		'save it
		lua_pushvalue( getLuaState(),-1 )
		_fenv	= luaL_ref( getLuaState(),LUA_REGISTRYINDEX )

		'set self/super object
		lua_pushvalue( getLuaState(),-1 )
		lua_setfield( getLuaState(),-2,"self" )
		lua_pushobject( Self )
		lua_setfield( getLuaState(),-2,"super" )
		'set meta indices
		lua_pushcfunction( getLuaState(), IndexSelf )
		lua_setfield( getLuaState(),-2,"__index" )
		lua_pushcfunction( getLuaState(), NewIndexSelf )
		lua_setfield( getLuaState(),-2,"__newindex" )

		'set fenv metatable
		lua_pushvalue( getLuaState(),-1 )
		lua_setmetatable( getLuaState(),-2 )

		'ready!
		lua_setfenv( getLuaState(),-2 )
		If lua_pcall( getLuaState(),0,0,0 ) Then DumpError()
	End Method

	Method DumpError()
		Print "#################################"
		WriteStdout "LUA ERROR in Engine "+Self.id+"~n"
		WriteStdout lua_tostring( getLuaState(),-1 )+"~n"
		Print "#################################"
	End Method


	Method lua_pushChunk:Int()
		If Not _chunk
			If luaL_loadstring( getLuaState(),_source )
				WriteStdout "Error loading script :~n" + lua_tostring( getLuaState(),-1 ) + "~n"
				lua_pop getLuaState(),1
				Return False
			EndIf
			_chunk=luaL_ref( getLuaState(),LUA_REGISTRYINDEX )
		EndIf
		lua_rawgeti( getLuaState() ,LUA_REGISTRYINDEX,_chunk )
		Return True
	End Method

	' create a table and load with array contents
	Method lua_pushArray( obj:Object )
		Local typeId:TTypeId=TTypeId.ForObject( obj )
		Local size:Int = typeId.ArrayLength(obj)

		lua_createtable( getLuaState(),size+1,0 )

		'lua is not zero based as BlitzMax is... so we have to add one entry at the first pos
		lua_pushinteger( getLuaState(), 0 )
		lua_pushinteger( getLuaState(), -1 )
		lua_settable( getLuaState(), -3 )


		For Local i:Int = 0 until size

			' the index +1 as not zerobased
			lua_pushinteger( getLuaState(), i+1)

			Select typeId.ElementType()
				Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId
					lua_pushinteger( getLuaState(), typeId.GetArrayElement(obj, i).ToString().ToInt() )
				Case FloatTypeId
					lua_pushnumber( getLuaState(), typeId.GetArrayElement(obj, i).ToString().ToFloat() )
				Case DoubleTypeId
					lua_pushnumber( getLuaState(), typeId.GetArrayElement(obj, i).ToString().ToDouble() )
				Case StringTypeId
					Local s:String = typeId.GetArrayElement(obj, i).ToString()
					lua_pushlstring( getLuaState(), s, s.length )
				Case ArrayTypeId
					Self.lua_pushArray( typeId.GetArrayElement(obj, i) )
				Default ' for everything else, we just push the object..
					Self.lua_pushobject( typeId.GetArrayElement(obj, i) )
			End Select

			lua_settable( getLuaState(), -3 )
		Next
	End Method

	'calls getobjmetatable
	Method lua_pushobject( obj:Object )
		lua_boxobject( getLuaState(),obj )
		lua_rawgeti( getLuaState(),LUA_REGISTRYINDEX, getObjMetaTable())
		lua_setmetatable( getLuaState(),-2 )
	End Method

	'from MaxLua
	'but added _private / _expose ... checks
			Method getObjMetaTable:Int()
				If Not _initDone
					lua_newtable( getLuaState() )
					lua_pushcfunction( getLuaState(),lua_gcobject )
					lua_setfield( getLuaState(),-2,"__gc" )
					lua_pushcfunction( getLuaState(), IndexObject )
					lua_setfield( getLuaState(),-2,"__index" )
					lua_pushcfunction( getLuaState(), NewIndexObject )
					lua_setfield( getLuaState(),-2,"__newindex" )
					_objMetaTable = luaL_ref( getLuaState(), LUA_REGISTRYINDEX )

					_initDone=True
				EndIf
				Return _objMetaTable
			End Method

			'adding a new method/field/func to lua
			Method Index:Int( )
				Local obj:Object		= lua_unboxobject( getLuaState(),1 )
				Local typeId:TTypeId	= TTypeId.ForObject( obj )
				Local ident:String		= lua_tostring( getLuaState(),2 )

				'only expose if type set to get exposed
				if not typeId.MetaData("_exposeToLua") then return false
				local exposeType:string = typeId.MetaData("_exposeToLua")

			'	print "registering ... "+ident

				'PRIVATE...do not add private functions/methods
				'so method _myMethod() is private, same for _myField:int = 0
				'lua constant/var to access global: _G
				if Chr( ident[0] ) =  "_" and ident <> "_G" then return True

				Local mth:TMethod = typeId.FindMethod( ident )
				'thing we have to push is a method
				If mth
					'PRIVATE...do not add private functions/methods
					if mth.MetaData("_private") then return True
					'only expose the children with explicit mention
					if exposeType = "selected" AND not mth.MetaData("_exposeToLua") then return True

					lua_pushvalue( getLuaState(),1 )
					lua_pushlightobject( getLuaState(),mth )
					lua_pushcclosure( getLuaState(),Invoke,2 )
					Return True
				EndIf

				'thing we have to push is a field
				Local fld:TField = typeId.FindField( ident )
				If fld= Null Then Return False

				'PRIVATE...do not add private functions/methods
				if fld.MetaData("_private") then return True
				'only expose the children with explicit mention
				if exposeType = "selected" AND not fld.MetaData("_exposeToLua") then return True

				Select fld.TypeId() ' BaH - added more types
					Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId
						lua_pushinteger( getLuaState(),fld.GetInt(obj) )
					Case FloatTypeId
						lua_pushnumber( getLuaState(),fld.GetFloat(obj) )
					Case DoubleTypeId
						lua_pushnumber( getLuaState(),fld.GetDouble(obj) )
					Case StringTypeId
						Local t:String = fld.GetString( obj )
						lua_pushlstring( getLuaState(),t,t.length )
					Case ArrayTypeId
						lua_pushArray( fld.Get(obj) )
					Default
						lua_pushobject( fld.Get(obj) )
				End Select
				Return True
			End Method

			Method NewIndex:Int( )
				Local obj:Object		= lua_unboxobject( getLuaState(),1 )
				Local typeId:TTypeId	= TTypeId.ForObject( obj )

				Local ident:String		= lua_tostring( getLuaState(),2 )
				Local mth:TMethod		= typeId.FindMethod( ident )
				If mth Then Throw "newIndex ERROR"

				'only expose if type set to get exposed
				if not typeId.MetaData("_exposeToLua") then print "Lua: Type "+typeId.name()+" not exposed to Lua"; return false
				local exposeType:string = typeId.MetaData("_exposeToLua")


				Local fld:TField=typeId.FindField( ident )
				If fld
					'PRIVATE...do not allow write to  private functions/methods
					'check could be removed if performance critical
					if fld.MetaData("_private") then return True
					'only set values of children with explicit mention
					if exposeType = "selected" AND not fld.MetaData("_exposeToLua") then return True
					if fld.MetaData("_exposeToLua")<>"rw" then print "LUA: "+typeId.name()+"."+ident+" is read-only";return true

					Select fld.TypeId()
						Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId
							fld.SetInt( obj,lua_tointeger( getLuaState(),3 ) )
						Case FloatTypeId
							fld.SetFloat( obj,lua_tonumber( getLuaState(),3 ) )
						Case DoubleTypeId
							fld.SetDouble( obj,lua_tonumber( getLuaState(),3 ) )
						Case StringTypeId
							fld.SetString( obj,lua_tostring( getLuaState(),3 ) )
						Default
							fld.Set( obj,lua_unboxobject( getLuaState(),3 ) )
					End Select
					Return True
				EndIf
				Print "newindex: ident not found: "+ident
			End Method

			'functions so we can push them to lua

				'they get called if a script tries to run a method/func/field from a blitzmax object
				Function IndexObject:Int( fromLuaState:Byte Ptr )
					Local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)
					If engine And engine.Index( ) Then Return 1
				End Function

				Function NewIndexObject:Int( fromLuaState:Byte Ptr)
					Local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)
					If engine And engine.NewIndex( ) Then Return True
					Throw "newindexobject ERROR"
				End Function


				Function IndexSelf:Int( fromLuaState:Byte Ptr )
					Local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)

					lua_getfield( engine.getLuaState(),1,"super" )
					lua_replace( engine.getLuaState(),1 )
					If engine.Index( ) Then Return 1

					lua_remove( engine.getLuaState(),1 )
					lua_gettable( engine.getLuaState(),LUA_GLOBALSINDEX )
					Return 1
				End Function

				Function NewIndexSelf( fromLuaState:Byte Ptr )
					'local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)
					lua_rawset( fromLuaState,1 )
				End Function

				Function Invoke:Int( fromLuaState:Byte Ptr )
					Local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)
					Return engine._Invoke()
				End Function


			Method _Invoke:Int()
				Local obj:Object		= lua_unboxobject( getLuaState(),LUA_GLOBALSINDEX-1 )
				Local meth:TMethod		= TMethod( lua_tolightobject( getLuaState(),LUA_GLOBALSINDEX-2 ) )
				Local tys:TTypeId[]		= meth.ArgTypes()
				Local args:Object[tys.length]

				For Local i:Int = 0 Until args.length
					Select tys[i]
						Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId
							args[i]=String.FromInt( lua_tointeger( getLuaState(),i+1 ) )
						Case FloatTypeId
							args[i]=String.FromFloat( lua_tonumber( getLuaState(),i+1 ) )
						Case DoubleTypeId
							args[i]=String.FromDouble( lua_tonumber( getLuaState(),i+1 ) )
						Case StringTypeId
							args[i]=lua_tostring( getLuaState(),i+1 )
						Default
							args[i]=lua_unboxobject( getLuaState(),i+1 )
					End Select
				Next
				Local t:Object=meth.Invoke( obj,args )
				local typeId:TTypeID = meth.TypeId()
				if object[](t).length > 0 then typeId = ArrayTypeId

				Select typeId
					Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId
						lua_pushinteger( getLuaState(),t.ToString().ToInt() )
					Case FloatTypeId
						lua_pushnumber( getLuaState(),t.ToString().ToFloat() )
					Case DoubleTypeId
						lua_pushnumber( getLuaState(),t.ToString().ToDouble() )
					Case StringTypeId
						Local s:String = t.ToString()
						lua_pushlstring( getLuaState(),s,s.length )
					Case ArrayTypeId
						lua_pushArray( t )
					Default
						lua_pushobject( t )
				End Select
				Return True
			End Method

' end maxlua import



	Method CallLuaFunction:Object(name:String, args:Object[] = Null)
		'push fenv
		lua_rawgeti( getLuaState(),LUA_REGISTRYINDEX,_fenv )


		lua_getfield( getLuaState(),-1,name )
		If lua_isnil( getLuaState(),-1 )
			lua_pop( getLuaState(),2 )
			Return Null
		EndIf
		For Local i:Int = 0 Until args.length
			Local typeId:TTypeId = TTypeId.ForObject( args[i] )
			Select typeId
				Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId
					lua_pushinteger( getLuaState(), args[i].ToString().ToInt() )
				Case FloatTypeId
					lua_pushnumber( getLuaState(), args[i].ToString().ToFloat() )
				Case DoubleTypeId
					lua_pushnumber( getLuaState(), args[i].ToString().ToDouble() )
				Case StringTypeId
					Local s:String = args[i].ToString()
					lua_pushlstring( getLuaState() ,s,s.length )
				Case ArrayTypeId
					Self.lua_pushArray( args[i] )
				Default
					Self.lua_pushobject( args[i] )
			End Select
		Next
		If lua_pcall( getLuaState(),args.length,1,0 ) Then DumpError()

		Local ret:Object
		If Not lua_isnil( getLuaState(),-1 ) Then ret = lua_tostring( getLuaState(), -1 )

		' pop the result
		lua_pop( getLuaState(),1 )

		' pop the fenv ?
		lua_pop( getLuaState(),1 )

		Return ret
	End Method



	'Once registered, the object can be accessed from within Lua scripts using the @ObjName identifer.
	Method RegisterBlitzmaxObject(Obj:Object, ObjName:String)
		lua_pushobject( obj )
		lua_setglobal( getLuaState(),ObjName )
	End Method

	Method RegisterInt( name:String, value:Int )
		lua_pushinteger getLuaState(),value
		lua_setfield getLuaState(),LUA_GLOBALSINDEX,name
	End Method

	Method RegisterFunction( name:String,value:Byte Ptr )
		lua_pushcclosure( getLuaState(),value,0 )
		lua_setfield( getLuaState(),LUA_GLOBALSINDEX,name )
	End Method

End Type
