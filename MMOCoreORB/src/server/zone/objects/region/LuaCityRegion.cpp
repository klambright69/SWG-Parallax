
#include "server/zone/objects/region/LuaCityRegion.h"
#include "server/zone/objects/region/CityRegion.h"

const char LuaCityRegion::className[] = "LuaCityRegion";

Luna<LuaCityRegion>::RegType LuaCityRegion::Register[] = {
		{ "_setObject", &LuaCityRegion::_setObject },
		{ "_getObject", &LuaCityRegion::_getObject },
		{ "isClientRegion", &LuaCityRegion::isClientRegion },
		// 10/13/26 klambright - Exposes CityRegion::getCityRank() to Lua so screenplays/cities/city_overhead_traffic.lua can limit overhead traffic and sound to rank 7+ cities; interacts with CityRegion.idl and the CityRegion() Lua wrapper in object_manager.lua.
		{ "getCityRank", &LuaCityRegion::getCityRank },
		//--->END OF MODIFICATION - kl<-- continue
		{ 0, 0 }
};

LuaCityRegion::LuaCityRegion(lua_State *L) {
	realObject = reinterpret_cast<CityRegion*>(lua_touserdata(L, 1));
}

LuaCityRegion::~LuaCityRegion() {
}

int LuaCityRegion::_getObject(lua_State* L) {
	if (realObject == nullptr)
		lua_pushnil(L);
	else
		lua_pushlightuserdata(L, realObject.get());

	return 1;
}

int LuaCityRegion::_setObject(lua_State* L) {
	realObject = reinterpret_cast<CityRegion*>(lua_touserdata(L, -1));

	return 0;
}

int LuaCityRegion::isClientRegion(lua_State* L) {
	bool val = realObject->isClientRegion();

	lua_pushboolean(L, val);

	return 1;
}

// 10/13/26 klambright - Exposes CityRegion::getCityRank() to Lua so screenplays/cities/city_overhead_traffic.lua can limit overhead traffic and sound to rank 7+ cities; interacts with CityRegion.idl and the CityRegion() Lua wrapper in object_manager.lua.
int LuaCityRegion::getCityRank(lua_State* L) {
	lua_pushinteger(L, realObject->getCityRank());

	return 1;
}
//--->END OF MODIFICATION - kl<--
