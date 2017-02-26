/*
 * Ronny Otto: added "THREADED" definition to make it compileable in
 * BlitzMax threaded mode.
 */
#ifndef THREADED
	#define THREADED
#endif

#include <brl.mod/blitz.mod/blitz.h>

#include <pub.mod/lua.mod/lua-5.1.4/src/lua.h>

void lua_boxobject( lua_State *L,BBObject *obj ){
	void *p;
	BBRETAIN( obj );
	p=lua_newuserdata( L,4 );
	*(BBObject**)p=obj;
}

BBObject *lua_unboxobject( lua_State *L,int index ){
	void *p;
	p=lua_touserdata( L,index );
	if(!p) {
		printf("LUA: unbox object invalid\n");
		return &bbNullObject;
	}
	return *(BBObject**)p;
}


void lua_pushlightobject( lua_State *L,BBObject *obj ){
	lua_pushlightuserdata( L,obj );
}

BBObject *lua_tolightobject( lua_State *L,int index ){
	return (BBObject*)( lua_touserdata( L,index ) );
}

int lua_gcobject( lua_State *L ){
	BBObject *obj=lua_unboxobject( L,1 );
	BBRELEASE( obj );
	return 1;
}
