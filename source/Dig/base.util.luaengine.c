#ifndef THREADED
	#define THREADED
#endif

#include <brl.mod/blitz.mod/blitz.h>

#include <pub.mod/lua.mod/lua-5.1.4/src/lua.h>


static void lua_printStackTrace(lua_State *L, int indent) {

    lua_Debug ar;
    int level = 0;

    char pad[64];
    int i;

    if (indent < 0) indent = 0;
    if (indent > 63) indent = 63;

    for (i = 0; i < indent; ++i) {
        pad[i] = ' ';
    }
    pad[indent] = '\0';

    printf("%sSTACK TRACE:\n", pad);

    while (lua_getstack(L, level, &ar)) {

        lua_getinfo(L, "nSl", &ar);

        printf("%s[%d] %s:%d (%s)\n",
            pad,
            level,
            ar.short_src,
            ar.currentline,
            ar.name ? ar.name : "unknown");

        level++;
    }
}

//from brl.reflection
BBClass* Luaengine_bbRefGetObjectClass(BBObject* p) {
	return p->clas;
}
BBClass* Luaengine_bbRefGetSuperClass(BBClass* clas) {
	return clas->super;
}
void Luaengine_bbRefAssignObject(BBObject** p, BBObject* t) {
	*p = t;
}
void* Luaengine_bbRefObjectFieldPtr(BBObject* obj, size_t offset) {
	return (char*)obj + offset;
}



//merged blitz_string.c's ascii_lower and ascii_upper
static inline unsigned int ascii_fold(unsigned int c) {
    return c + ((unsigned int)(c - 'A') <= 25u) * 32u;
}

int strcmp_ascii_nocase(const char *a, const char *b) {
    unsigned char ca, cb;

    while ((ca = *a) && (cb = *b)) {
        unsigned int la = ascii_fold(ca);
        unsigned int lb = ascii_fold(cb);

        if (la != lb)
            return (int)la - (int)lb;

        ++a;
        ++b;
    }

    return (int)(unsigned char)*a - (int)(unsigned char)*b;
}


// Function to hash a Lua string
BBULONG lua_StringHash(lua_State* L, int index) {
    size_t length;
    const char* str = lua_tolstring(L, index, &length);

    // If the Lua value is not a string, return 0 as a default
    if (!str) {
        return 0;
    }

	// Convert the UTF-8 Lua string to BBChar (same as UTF-16 if BBChar is 2 bytes)
    size_t utf16Length = length;
    BBChar* utf16Str = (BBChar*)malloc((utf16Length + 1) * sizeof(BBChar));
    for (size_t i = 0; i < length; ++i) {
        utf16Str[i] = (BBChar)str[i];
    }
    utf16Str[length] = 0; // Null terminate

    // Compute and return the xxHash hash for the BBChar converted Lua string
    BBULONG hash = XXH3_64bits((const char*)utf16Str, utf16Length * sizeof(BBChar));

    // Free the allocated memory for the UTF-16 string
    free(utf16Str);

    //return hash;
    //current solution in blitz_string.c:
	return (BBUINT)(hash ^ (hash >> 32));
}


// Function to hash a Lua string case-insensitively
BBUINT lua_LowerStringHash(lua_State* L, int index) {
    size_t length;
    const char* str = lua_tolstring(L, index, &length);

    // If the Lua value is not a string, return 0 as a default
    if (!str) {
        return 0;
    }

    // Convert the UTF-8 Lua string to BBChar (same as UTF-16 if BBChar is 2 bytes)
    size_t utf16Length = length;
    BBChar* utf16Str = (BBChar*)malloc((utf16Length + 1) * sizeof(BBChar)); // +1 for null terminator
    for (size_t i = 0; i < length; ++i) {
        utf16Str[i] = (BBChar)str[i];
    }
    utf16Str[length] = 0; // Null terminate

    // Convert to lowercase directly on the BBChar (UTF-16) array
    for (size_t i = 0; i < length; ++i) {
        if (utf16Str[i] >= 'A' && utf16Str[i] <= 'Z') {
            utf16Str[i] += 32; // Convert uppercase to lowercase
        }
    }

    // Compute and return the xxHash hash for the lowercase BBChar string
    BBULONG hash = XXH3_64bits((const char*)utf16Str, utf16Length * sizeof(BBChar));

    // Free the allocated memory for the BBChar string
    free(utf16Str);

    //return hash;
    //current solution in blitz_string.c:
	return (BBUINT)(hash ^ (hash >> 32));
}


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
		printf("     index=%d type=%s\n", index, lua_typename(L, lua_type(L, index)));
		lua_printStackTrace(L, 5);
        fflush(stdout);
        return &bbNullObject;
    }

    if (!lua_getmetatable(L, index)) {
        printf("LUA: unbox object misses metatable\n");
		lua_printStackTrace(L, 5);
        fflush(stdout);
        return &bbNullObject;
    }

    lua_rawgeti(L, LUA_REGISTRYINDEX, _objMetaTable);
    if (!lua_rawequal(L, -1, -2)) {
        lua_pop(L, 2); // Pop both metatables
        printf("LUA: unbox object contains invalid metatable\n");
		lua_printStackTrace(L, 5);
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
		lua_printStackTrace(L, 5);
        fflush(stdout);
        return 0;
    }
    struct BBObjectContainer * uc = *(struct BBObjectContainer **)p;
    if (uc) {
        GC_FREE(uc);
    }
    return 0;
}
