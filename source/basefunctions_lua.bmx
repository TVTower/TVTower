SuperStrict
Import Pub.Lua
Import BRL.Reflection
Import brl.retro
'from maxlua
Import "basefunctions_lua.c"
Extern
	Function lua_boxobject( L:Byte Ptr,obj:Object )
	Function lua_unboxobject:Object( L:Byte Ptr,index:int)
	Function lua_pushlightobject( L:Byte Ptr,obj:Object )
	Function lua_tolightobject:Object( L:Byte Ptr,index:int )
	Function lua_gcobject( L:Byte Ptr )
End Extern
'end from maxlua


Type TLuaEngine
	global list:TList	= CreateList()
	global lastID:int = 0
	field id:int = 0

	field _luaState:Byte Ptr		'Pointer to current lua environment
	field _source:string	= ""	'current code
	field _chunk:int		= 0		'current code loaded as chunk
	field _initDone:int		= 0		'meta table set up finished?
	field _objMetaTable:int			'for GC ... from MaxLua
	Field _fenv:int					'we store other objects in our metatable - we are responsible for them
									'fenv should be known from Lua itself

	Function Create:TLuaEngine( source:string )
		local obj:TLuaEngine = New TLuaEngine.SetSource( source )
		'init fenv and register self
		obj.RegisterToLua()
		obj.lastID :+1
		obj.id = obj.lastID

		self.list.addLast(obj)
		return obj
	End Function

	Method Delete()
		luaL_unref( getLuaState(),LUA_REGISTRYINDEX, _fenv )
		luaL_unref( getLuaState(),LUA_REGISTRYINDEX, _chunk )
	End Method


	Function FindEngine:TLuaEngine(LuaState:Byte Ptr)
		'local num:int = 1
		for local engine:TLuaEngine = eachin TLuaEngine.list
			if engine._luaState = LuaState
				'print "engine number "+num
				return engine
			endif
			'num:+1
		Next
		print "engine not found"
		return null
	End Function

	Method getLuaState:Byte Ptr()
		If Not self._luaState
			self._luaState=luaL_newstate()
			luaL_openlibs self._luaState
		EndIf
		Return self._luaState
	End Method

	Method getSource:string()
		Return _source
	End Method

	Method SetSource:TLuaEngine( source:string )
		_source=source
		If _chunk
			LuaL_unref( getLuaState(),LUA_REGISTRYINDEX,_chunk )
			_chunk=0
		EndIf

		self.RegisterToLua()

		Return Self
	End Method

	'we are parent of other registered objects
	Method RegisterToLua:int()
		'push class block
		If Not lua_pushchunk() then Return null

		'create fenv table
		lua_newtable( getLuaState() )

		'save it
		lua_pushvalue( getLuaState(),-1 )
		_fenv	= luaL_ref( getLuaState(),LUA_REGISTRYINDEX )

		'set self/super object
		lua_pushvalue( getLuaState(),-1 )
		lua_setfield( getLuaState(),-2,"self" )
		lua_pushobject( self )
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
		If lua_pcall( getLuaState(),0,0,0 ) then DumpError()
	End Method

	Method DumpError()
		WriteStdout "LUA ERROR in Engine "+self.id+"~n"
		WriteStdout lua_tostring( getLuaState(),-1 )
	End Method


	Method lua_pushChunk:int()
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

		lua_createtable( getLuaState(),size,0 )

		For Local i:Int = 0 Until size

			' the index
			lua_pushinteger( getLuaState(), i)

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
					self.lua_pushArray( typeId.GetArrayElement(obj, i) )
				Default ' for everything else, we just push the object..
					self.lua_pushobject( typeId.GetArrayElement(obj, i) )
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
			Method getObjMetaTable:int()
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
			Method Index:int( )
				Local obj:Object		= lua_unboxobject( getLuaState(),1 )
				Local typeId:TTypeId	= TTypeId.ForObject( obj )
				Local ident:string		= lua_tostring( getLuaState(),2 )

				Local mth:TMethod		= typeId.FindMethod( ident )
				'thing we have to push is a method
				If mth
					lua_pushvalue( getLuaState(),1 )
					lua_pushlightobject( getLuaState(),mth )
					lua_pushcclosure( getLuaState(),Invoke,2 )
					Return True
				EndIf

				'thing we have to push is a field
				Local fld:TField		= typeId.FindField( ident )
				If fld= null then return false

				Select fld.TypeId() ' BaH - added more types
					Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId
						lua_pushinteger( getLuaState(),fld.GetInt( obj ))
					Case FloatTypeId
						lua_pushnumber( getLuaState(),fld.GetFloat( obj ))
					Case DoubleTypeId
						lua_pushnumber( getLuaState(),fld.GetDouble( obj ))
					Case StringTypeId
						Local t:string = fld.GetString( obj )
						lua_pushlstring( getLuaState(),t,t.length )
					Default
						lua_pushobject( fld.Get( obj ) )
				End Select
				Return True
			End Method

			Method NewIndex:int( )
				Local obj:Object		= lua_unboxobject( getLuaState(),1 )
				Local typeId:TTypeId	= TTypeId.ForObject( obj )

				Local ident:string		= lua_tostring( getLuaState(),2 )

				Local mth:TMethod		= typeId.FindMethod( ident )
				If mth then Throw "newIndex ERROR"

				Local fld:TField=typeId.FindField( ident )
				If fld
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
				endif
				print "newindex: ident not found: "+ident
			End Method

			'functions so we can push them to lua

				'they get called if a script tries to run a method/func/field from a blitzmax object
				Function IndexObject:int( fromLuaState:Byte Ptr )
					local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)
					If engine and engine.Index( ) then Return 1
				End Function

				Function NewIndexObject:int( fromLuaState:Byte Ptr)
					local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)
					If engine and engine.NewIndex( ) then Return true
					Throw "newindexobject ERROR"
				End Function


				Function IndexSelf:int( fromLuaState:Byte Ptr )
					local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)

					lua_getfield( engine.getLuaState(),1,"super" )
					lua_replace( engine.getLuaState(),1 )
					If engine.Index( ) then Return 1

					lua_remove( engine.getLuaState(),1 )
					lua_gettable( engine.getLuaState(),LUA_GLOBALSINDEX )
					Return 1
				End Function

				Function NewIndexSelf( fromLuaState:Byte Ptr )
					'local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)
					lua_rawset( fromLuaState,1 )
				End Function

				Function Invoke:int( fromLuaState:Byte Ptr )
					local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)
					return engine._Invoke()
				End Function


			Method _Invoke:int()
				Local obj:Object		= lua_unboxobject( getLuaState(),LUA_GLOBALSINDEX-1 )
				Local meth:TMethod		= TMethod( lua_tolightobject( getLuaState(),LUA_GLOBALSINDEX-2 ) )
				Local tys:TTypeId[]		= meth.ArgTypes()
				local args:Object[tys.length]

				For Local i:int = 0 Until args.length
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
				Select meth.TypeId()
					Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId
						lua_pushinteger( getLuaState(),t.ToString().ToInt() )
					Case FloatTypeId
						lua_pushnumber( getLuaState(),t.ToString().ToFloat() )
					Case DoubleTypeId
						lua_pushnumber( getLuaState(),t.ToString().ToDouble() )
					Case StringTypeId
						Local s:string = t.ToString()
						lua_pushlstring( getLuaState(),s,s.length )
					Default
						lua_pushobject( t )
				End Select
				Return true
			End Method

' end maxlua import



	Method CallLuaFunction:object(name:String, args:Object[] = Null)
		'push fenv
		lua_rawgeti( getLuaState(),LUA_REGISTRYINDEX,_fenv )


		lua_getfield( getLuaState(),-1,name )
		If lua_isnil( getLuaState(),-1 )
			lua_pop( getLuaState(),2 )
			Return null
		EndIf
		For Local i:int = 0 Until args.length
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
					self.lua_pushArray( args[i] )
				Default
					self.lua_pushobject( args[i] )
			End Select
		Next
		If lua_pcall( getLuaState(),args.length,1,0 ) then DumpError()

		Local ret:Object
		If Not lua_isnil( getLuaState(),-1 ) then ret = lua_tostring( getLuaState(), -1 )

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

	Method RegisterInt( name:string, value:int )
		lua_pushinteger getLuaState(),value
		lua_setfield getLuaState(),LUA_GLOBALSINDEX,name
	End Method

	Method RegisterFunction( name:string,value:Byte Ptr )
		lua_pushcclosure( getLuaState(),value,0 )
		lua_setfield( getLuaState(),LUA_GLOBALSINDEX,name )
	End Method

End Type
