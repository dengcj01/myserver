#include "Script.h"

#include "../MainThread.h"
#include "../player/Player.h"
#include "../player/PlayerMgr.h"
#include "../configparse/CfgMgr.h"
#include "../../../common/log/Log.h"
#include "../../../common/Timer.hpp"
#include "../../../common/Rank.hpp"
#include "../../../common/Filter.hpp"
#include "../../../common/ParseConfig.hpp"
#include "../../../common/Tools.hpp"
#include "../fight/FightMgr.h"

#include <string>
#include <stdio.h>

extern std::unordered_map<uint16_t, MessageBaseInfo> gMessIdMapName;
extern std::unordered_map<const char *, MessageBaseInfo> gNameMapMessId;

Script::~Script()
{
	closeLua();
}

void Script::doFile(const char *path)
{
	lua_pushcclosure(l, LuaBind::errFunc, 0);
	int stackTop = lua_gettop(l);
	if (luaL_loadfile(l, path) == 0) // 没有错误
	{
		if (lua_pcall(l, 0, 0, stackTop)) // 0成功
		{
			lua_pop(l, 1);
		}
	}
	else
	{
		logInfo("dofile error: %s", lua_tostring(l, -1));
		lua_pop(l, 1);
	}
	lua_pop(l, 1);
}

void Script::openLua(const char *path)
{	
	l = luaL_newstate();
	if (!l)
	{
		logQuit("openLua err");
		_exit(0);
	}


	luaL_openlibs(l);

	reg();

	std::string luaPath = path;
	luaPath.append("logic/main.lua");
	doFile(luaPath.data());
}

void Script::closeLua()
{
	if (l)
	{
		lua_close(l);
		l = nullptr;
	}
}

void Script::onMessage(uint16_t messageId, uint64_t sessionId, const char *name, char *data, size_t len, bool cross, bool fromGate)
{
	if (!cross)
	{
		if (fromGate)
		{
			// Player *player = new Player();
			Player *player = gPlayerMgr.getPlayer(sessionId);
			if (!player)
			{
				logInfo("onMessage no find player %d", messageId);
				return;
			}
			LuaBind::CallLua cl(l, "dispatchGateClientMessage");
			if (cl.existFunc())
			{
				cl.call<void, void *>(player, player->getPid(), name, data, len, messageId);
			}
		}
		else
		{
			LuaBind::CallLua cl(l, "dispatchMasterMessage");
			if (cl.existFunc())
			{
				cl.call<void, void *>(gParseConfig.getMasterServerId(), 0, name, data, len, messageId);
			}
		}
	}
	else
	{
		LuaBind::CallLua cl(l, "dispatchLogicGameMessage");
		uint32_t serverId = gMainThread.getLogicServerId(sessionId);
		if (cl.existFunc())
		{
			cl.call<void, void *>(serverId, 0, name, data, len, messageId);
		}
	}
}

void Script::secondUpdate()
{
	LuaBind::CallLua cl(l, "gServerUpdate");
	long curTime = time(0);
	auto &data = gPlayerMgr.getOnlinePlayers();
	for (auto &e : data)
	{
		Player *player = e.second;
		uint32_t saveTime = player->saveTime_;
		if (saveTime > 0 && curTime >= saveTime)
		{
			player->saveBaseData();
			player->saveBagData();
			player->saveTime_ = 0;
		}
	}

	cl.call<void, void>(curTime);
}

void Script::serverCmd(Player *player, const std::string &cmd)
{
	LuaBind::CallLua cl(l, "gServerCmd");
	cl.call<void, void>(player, cmd);
}

void Script::fightEnd(uint64_t uid, bool res)
{
	LuaBind::CallLua cl(l, "gFightEndRes");
	cl.call<void, void>(uid, res);
}

void Script::callLuaTimer(uint64_t pid, const char *name, const char *tid, uint8_t timerc)
{
	Player *player = gPlayerMgr.getPlayerById(pid);
	if (!player)
	{
		// logInfo("callLuaTimer no player", pid);
		return;
	}

	LuaBind::CallLua cl(l, name);
	cl.call<void, void>(player, tid, timerc);
}

void luaLog(int lv, const char *txt)
{
	logInfo("%s", txt);
}

void Script::reg()
{

	regGloablFunc(luaLog, l);

	regClass(Tools, l);
	regGlobalVarNoSame(&gTools, "gTools", l);
	regClassFunc(Tools, createUniqueId, l);
	regClassFunc(Tools, reverServerId, l);
	regClassFunc(Tools, getMillisTime, l);
	//regClassFunc(Tools, isValidStr, l);
	regClassFunc(Tools, mallocTrim, l);
	regClassFunc(Tools, getClock, l);
	regClassFunc(Tools, get0Time, l);
	regClassFunc(Tools, getStringTime, l);
	regClassFunc(Tools, random, l);

	regClass(Timer, l);
	regGlobalVarNoSame(&gTimer, "gTimer", l);
	regClassFunc(Timer, add, l);
	regClassFunc(Timer, del, l);

	regClass(Filter, l);
	regGlobalVarNoSame(&gFilter, "gFilter", l);
	regClassFunc(Filter, add, l);
	regClassFunc(Filter, filter, l);
	regClassFunc(Filter, initFailPoint, l);


	regClass(MainThread, l);
	regGlobalVarNoSame(&gMainThread, "gMainThread", l);
	regClassFunc(MainThread, sendMessage2GameClient, l);
	regClassFunc(MainThread, parseProto, l);
	regClassFunc(MainThread, cacheMessage, l);
	regClassFunc(MainThread, addMailLog, l);
	regClassFunc(MainThread, getLogicSessionId, l);
	regClassFunc(MainThread, sendMessage2Master, l);
	regClassFunc(MainThread, saveGlobalData, l);
	regClassFunc(MainThread, sendMessage2GateClient, l);
	regClassFunc(MainThread, forceCloseSession, l);
	regClassFunc(MainThread, getLogicServerList, l);
	regClassFunc(MainThread, isValidStr, l);


	regClass(PlayerMgr, l);
	regGlobalVarNoSame(&gPlayerMgr, "gPlayerMgr", l);
	regClassFunc(PlayerMgr, getPlayerById, l);
	regClassFunc(PlayerMgr, getOnlinePlayers, l);
	regClassFunc(PlayerMgr, savePlayerModuleData, l);
	regClassFunc(PlayerMgr, testLoad, l);
	regClassFunc(PlayerMgr, testSave, l);
	regClassFunc(PlayerMgr, fakeLogin, l);
	regClassFunc(PlayerMgr, getFakePlayer, l);
	regClassFunc(PlayerMgr, loadFakePlayerData, l);
	regClassFunc(PlayerMgr, getZeroList, l);
	regClassFunc(PlayerMgr, cleanZeroList, l);
	regClassFunc(PlayerMgr, getOnlineCnt, l);

	regClass(Player, l);
	regClassFunc(Player, getSessionId, l);
	regClassFunc(Player, getCsessionId, l);
	regClassFunc(Player, getPid, l);
	regClassFunc(Player, itemEnough, l);
	regClassFunc(Player, costItems, l);
	regClassFunc(Player, itemEnough, l);
	regClassFunc(Player, addItems, l);
	regClassFunc(Player, getCreateTime, l);
	regClassFunc(Player, getName, l);
	regClassFunc(Player, getIcon, l);
	regClassFunc(Player, getPf, l);
	regClassFunc(Player, getPower, l);
	regClassFunc(Player, getLevel, l);
	regClassFunc(Player, getVip, l);
	regClassFunc(Player, getExp, l);
	regClassFunc(Player, getLoginTime, l);
	regClassFunc(Player, getGuildId, l);
	regClassFunc(Player, getChargeVal, l);
	regClassFunc(Player, getItemCount, l);
	regClassFunc(Player, removeItemById, l);
	regClassFunc(Player, removeItemByGuid, l);

	regClass(RankMgr, l);
	regGlobalVarNoSame(&gRankMgr, "gRankMgr", l);
	regClassFunc(RankMgr, initRank, l);
	regClassFunc(RankMgr, getRank, l);
	regClassFunc(RankMgr, delRank, l);
	regClassFunc(RankMgr, cleanRank, l);
	regClassFunc(RankMgr, save, l);

	regClass(RankItem, l);
	regClassFunc(RankItem, getId, l);
	regClassFunc(RankItem, getVal1, l);
	regClassFunc(RankItem, getVal2, l);
	regClassFunc(RankItem, getVal3, l);
	regClassFunc(RankItem, getServerId, l);

	regClass(Rank, l);
	regClassFunc(Rank, updateRank, l);
	regClassFunc(Rank, getRanking, l);
	regClassFunc(Rank, getRankItem, l);
	regClassFunc(Rank, getRankItemList, l);
	regClassFunc(Rank, getData, l);
	regClassFunc(Rank, delRankItemByRanking, l);
	regClassFunc(Rank, delRankItemById, l);

	regClass(ParseConfig, l);
	regGlobalVarNoSame(&gParseConfig, "gParseConfig", l);
	regClassFunc(ParseConfig, getMasterServerId, l);
	regClassFunc(ParseConfig, isGameServer, l);
	regClassFunc(ParseConfig, isMasterServer, l);
	regClassFunc(ParseConfig, getMasterIdx, l);
	regClassFunc(ParseConfig, getServerId, l);

	regClass(CfgMgr, l);
	regGlobalVarNoSame(&gCfgMgr, "gCfgMgr", l);
	regClassFunc(CfgMgr, loadItem, l);
	regClassFunc(CfgMgr, isHero, l);

	// regClass(FightMgr, l);
	// regGlobalVarNoSame(&gFightMgr, "gFightMgr", l);
	// regClassFunc(FightMgr, addRandom, l);
	// regClassFunc(FightMgr, addSeq, l);
	// regClassFunc(FightMgr, checkAndPack, l);

}
