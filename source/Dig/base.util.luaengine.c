#ifndef THREADED
	#define THREADED
#endif

#include <brl.mod/blitz.mod/blitz.h>

#include <pub.mod/lua.mod/lua-5.1.4/src/lua.h>

struct BBObjectContainer {
	BBObject * o;
};


void lua_boxobject(lua_State *L, BBObject *obj, int _objMetaTable) {
    struct BBObjectContainer *uc = (struct BBObjectContainer *)GC_MALLOC_UNCOLLECTABLE(sizeof(struct BBObjectContainer));
    if (!uc) {
        printf("LUA: Failed to allocate BBObjectContainer\n");
        fflush(stdout);
        return;
    }
    uc->o = obj;

    void *p = lua_newuserdata(L, sizeof(struct BBObjectContainer *));
    if (!p) {
        printf("LUA: Failed to allocate userdata\n");
        fflush(stdout);
        GC_FREE(uc);
        return;
    }
    *(struct BBObjectContainer **)p = uc;

    // Set the metatable
    lua_rawgeti(L, LUA_REGISTRYINDEX, _objMetaTable);
    lua_setmetatable(L, -2);
}


BBObject *lua_unboxobject(lua_State *L, int index, int _objMetaTable) {
    void *p = lua_touserdata(L, index);
    if (!p) {
        return &bbNullObject;
    }
    struct BBObjectContainer * uc = *(struct BBObjectContainer **)p;
    return uc ? uc->o : &bbNullObject;
}


BBObject *lua_unboxobject_debug(lua_State *L, int index, int _objMetaTable) {
    void *p = lua_touserdata(L, index);
    if (!p) {
        printf("LUA: unbox object contains invalid userdata (userdata is nil or not set/exposed correctly)\n");
        fflush(stdout);
        return &bbNullObject;
    }

    if (!lua_getmetatable(L, index)) {
        printf("LUA: unbox object misses metatable\n");
        fflush(stdout);
        return &bbNullObject;
    }

    lua_rawgeti(L, LUA_REGISTRYINDEX, _objMetaTable);
    if (!lua_rawequal(L, -1, -2)) {
        lua_pop(L, 2); // Pop both metatables
        printf("LUA: unbox object contains invalid metatable\n");
        fflush(stdout);
        return &bbNullObject;
    }
    lua_pop(L, 2); // Pop both metatables

    struct BBObjectContainer * uc = *(struct BBObjectContainer **)p;
    return uc ? uc->o : &bbNullObject;
}


void lua_pushbbstring( lua_State *L, BBString *s){
    char * c = bbStringToUTF8String(s);
    lua_pushstring(L, c);
    bbMemFree(c);
}

BBString *lua_tobbstring( lua_State *L, int index ) {
	size_t l;
	char * c = lua_tolstring(L, index, &l);
	if (c) {
		BBString * s = bbStringFromUTF8String(c);
		//no need to free the pointer, it is managed by lua !
		//bbMemFree(c);
		return s;
	}
	return &bbEmptyString;
}

void lua_pushlightobject( lua_State *L,BBObject *obj ){
	lua_pushlightuserdata( L,obj );
}

BBObject *lua_tolightobject( lua_State *L,int index ){
	return (BBObject*)( lua_touserdata( L,index ) );
}

int lua_gcobject(lua_State *L) {
    void *p = lua_touserdata(L, 1);
    if (!p) {
        printf("LUA: invalid userdata during __gc\n");
        fflush(stdout);
        return 0;
    }
    struct BBObjectContainer * uc = *(struct BBObjectContainer **)p;
    if (uc) {
        GC_FREE(uc);
    }
    return 0;
}
