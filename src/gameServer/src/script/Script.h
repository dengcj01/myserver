#pragma once

#include "../public/Lua.hpp"
#include "../../../common/Singleton.h"


#include <stddef.h>
#include <string>


struct lua_State;


class Player;

class Script : public Singleton<Script>
{
public:
	~Script();
public:
	void openLua(const char* path);
	void closeLua();
	void doFile(const char* path);
	void onMessage(uint16_t messageId, uint64_t sessionId, const char* name, char* data, size_t len, bool cross = false, bool fromGate = false);

	void fightEnd(uint64_t uid, bool res);
	void secondUpdate();
	void reg();
	void serverCmd(Player* player, const std::string& cmd);
	void callLuaTimer(uint64_t pid, const char* name, const char* tid, uint8_t timerc);

	lua_State *l;
};

#define gScript Script::instance()