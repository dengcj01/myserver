#include "Script.h"

#include "../MainThread.h"
#include "../player/Player.h"
#include "../player/PlayerMgr.h"
#include "../configparse/CfgMgr.h"
#include "../../../common/log/Log.h"
#include "../../../common/Timer.hpp"
#include "../public/Rank.hpp"
#include "../../../common/Filter.hpp"
#include "../../../common/ParseConfig.hpp"
#include "../../../common/Tools.hpp"
#include "../fight/FightMgr.h"
#include "../../../common/CommDefine.h"
#include <string>
#include <stdio.h>


extern std::unordered_map<uint16_t, MessageBaseInfo> gMessIdMapName;
extern std::unordered_map<const char *, MessageBaseInfo> gNameMapMessId;

Script::~Script()
{
	closeLua();
}

bool Script::doFile(const char *path)
{
	if (luaL_loadfile(l, path) == 0) // 没有错误
	{
		int ret = lua_pcall(l, 0, 0, 0);
		if(ret != LUA_OK)
		{
			logInfo("doFile error1 %s", lua_tostring(l, -1));
			return false;
		}
	}
	else
	{
		logInfo("dofile error2 %s", lua_tostring(l, -1));
		return false;
	}

	lua_settop(l, 0);
	return true;
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

    //lua_register(l, "myCFunction", myCFunction);

	reg();

	luaPath_ = path;
	luaPath_.append("logic/");
	std::string tmp = luaPath_;
	bool ret = doFile(tmp.append("main.lua").data());



	if(!ret)
	{
		_exit(0);
	}

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
				logInfo("onMessage no find player sess:%llu, mess:%d", sessionId, messageId);
				return;
			}

			uint64_t pid = player->pid_;
			double sTime = gTools.getClock();

			LuaBind::CallLua cl(l, "gDispatchGateClientMessage");
			cl.call<void, void *>(player, pid, name, data, len, messageId);

			double eTime = gTools.getClock();
			double ret = (eTime - sTime)*1000;
			if(ret > 10)
			{
				logInfo("出现耗时协议请立即优化 协议id: %d  耗时: %f 毫秒 pid:%llu", messageId, ret, pid);
			}
		}
		else
		{
			LuaBind::CallLua cl(l, "gDispatchMasterMessage");
			cl.call<void, void *>(gParseConfig.getMasterServerId(), 0, name, data, len, messageId);
		}
	}
	else
	{
		uint32_t serverId = gMainThread.getLogicServerId(sessionId);

		LuaBind::CallLua cl(l, "gDispatchLogicGameMessage");
		cl.call<void, void *>(serverId, 0, name, data, len, messageId); 
	}
}

void Script::secondUpdate()
{

	long curTime = gTools.getNowTime();
	bool ok = gTools.isWholeMinute(curTime);

	if(ok)
	{
		const auto& data = gPlayerMgr.getOnlinePlayers();
		uint32_t cnt = gPlayerMgr.getOnlineCnt();
		if(cnt > 0)
		{
			for (auto &e : data)
			{
				Player *player = e.second;
				uint32_t saveTime = player->saveTime_;
				if (saveTime > 0 && curTime >= saveTime)
				{
					player->saveBaseData();
					player->saveTime_ = 0;
				}
			}
		}

		LuaBind::CallLua cl(l, "gServerUpdate", 0);
		cl.call<void, void>(curTime);
	}



}

void Script::processHttp(Player* player, const std::string& str)
{
	if(!p)
	{
		p = new Player();
	}

	LuaBind::CallLua cl(l, "gProcessHttp");
	cl.call<void, void>(p, str);
}

void Script::serverCmd(Player *player, const std::string &fullCmd)
{

	std::string tmp = gTools.trim(fullCmd);
	std::vector<std::string> res = gTools.splitBydelimiter(tmp, " ");

	if(!player)
	{
		player = new Player();
	}

	if(res.size() > 0)
	{
		std::string& cmd = res[0];
		if(cmd == "rsf")
		{
			std::string tmp = luaPath_;
			doFile(tmp.append("reload.lua").data());
		}
		else
		{
			LuaBind::CallLua cl(l, "gServerCmd");
			cl.call<void, void>(player, fullCmd);
		}
	}
	else
	{
		printf("\n");
	}
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
		return;
	}

	LuaBind::CallLua cl(l, name);
	cl.call<void, void>(player, tid, timerc);
}

void luaLog(int lv, const char *txt)
{
	logInfo("%s", txt);
}

// int static cppFuncCreateUniqueId(lua_State* ls)
// {
// 	int64_t val = gTools.createUniqueId();
// 	LuaBind::setLuaVal(val, ls);
// 	return 1;
// }

// int static cppFuncGet0Time(lua_State* ls)
// {
// 	uint32_t nowTime = LuaBind::getLuaVal<uint32_t>(-1, ls);
// 	uint32_t val = gTools.get0Time(nowTime);
// 	LuaBind::setLuaVal(val, ls);
// 	return 1;
// }

// int static cppFuncGetClock(lua_State* ls)
// {
// 	double val = gTools.getClock();
// 	LuaBind::setLuaVal(val, ls);
// 	return 1;
// }

// int static cppFuncGetNowTime(lua_State* ls)
// {
// 	uint32_t val = gTools.getNowTime();
// 	LuaBind::setLuaVal(val, ls);
// 	return 1;
// }

// int static cppFuncGetNowTimeByDate(lua_State* ls)
// {
// 	int year = LuaBind::getLuaVal<int>(-6, ls);
// 	int month = LuaBind::getLuaVal<int>(-5, ls);
// 	int day = LuaBind::getLuaVal<int>(-4, ls);
// 	int hour = LuaBind::getLuaVal<int>(-3, ls);
// 	int min = LuaBind::getLuaVal<int>(-2, ls);
// 	int sec = LuaBind::getLuaVal<int>(-1, ls);	

// 	auto val = gTools.getNowTimeByDate(year, month, day, hour, min, sec);
// 	LuaBind::setLuaVal(val, ls);
// 	return 1;
// }


// int static cppFuncGetNowYMD(lua_State* ls)
// {
// 	std::string val = gTools.getNowYMD();
// 	LuaBind::setLuaVal(val, ls);
// 	return 1;
// }

// int static cppFuncGetDayOfWeek(lua_State* ls)
// {	
// 	auto nowTime = LuaBind::getLuaVal<uint32_t>(-1, ls);
// 	auto val = gTools.getDayOfWeek(nowTime);
// 	LuaBind::setLuaVal(val, ls);
// 	return 1;
// }

// int static cppFuncTimestampToString(lua_State* ls)
// {	
// 	auto nowTime = LuaBind::getLuaVal<uint32_t>(-1, ls);
// 	auto val = gTools.timestampToString(nowTime);
// 	LuaBind::setLuaVal(val, ls);
// 	return 1;
// }

// int static cppFuncAddTimer(lua_State* ls)
// {	
// 	auto expire = LuaBind::getLuaVal<uint32_t>(-4, ls);
// 	auto funcName = LuaBind::getLuaVal<const char*>(-3, ls);
// 	auto pid = LuaBind::getLuaVal<int64_t>(-2, ls);
// 	auto opt = LuaBind::getLuaVal<uint8_t>(-1, ls);

// 	Args *args = (Args *)malloc(sizeof(Args));
// 	args->lua_ = true;
// 	memset(args->luaFunc_, 0, 15);
// 	strncpy(args->luaFunc_, funcName, strlen(funcName));
// 	args->pid_ = pid;
// 	auto eid = gTimer.add(expire, nullptr, args, opt);
// 	LuaBind::setLuaVal(eid, ls);
// 	return 1;
// }

// int static cppFuncDelTimer(lua_State* ls)
// {	
// 	auto eid = LuaBind::getLuaVal<char*>(-1, ls);
// 	gTimer.del(eid);

// 	return 0;
// }

// int static cppFuncAddFilter(lua_State* ls)
// {	
// 	auto str = LuaBind::getLuaVal<const char*>(-1, ls);
// 	gFilter.add(str);
// 	return 0;
// }

// int static cppFuncInitFilterFailPoint(lua_State* ls)
// {	
// 	gFilter.initFailPoint();
// 	return 0;
// }

// int static cppFuncFilterChat(lua_State* ls)
// {	
// 	auto str = LuaBind::getLuaVal<const char*>(-1, ls);
// 	std::string val = gFilter.filterChat(str);
// 	LuaBind::setLuaVal(val, ls);
// 	return 1;
// }

// int static cppFuncInitFilterName(lua_State* ls)
// {	
// 	auto str = LuaBind::getLuaVal<const char*>(-1, ls);
// 	std::string val = gFilter.filterChat(str);
// 	LuaBind::setLuaVal(val, ls);
// 	return 1;
// }

// int static cppFuncSendMessage2GameClient(lua_State* ls)
// {	
// 	auto sessionId = LuaBind::getLuaVal<uint64_t>(-4, ls);
// 	auto name = LuaBind::getLuaVal<const char*>(-3, ls);
// 	std::unique_ptr<google::protobuf::Message> mess = Codec::encoder(name, ls, 4);

// 	return 0;
// }


void Script::reg()
{

	regGlobalVarSame(BackgroundKick, l);
	regGlobalVarSame(ChangeNameErrCodeRepeated, l);


	regGloablFunc(luaLog, l);


	regClass(Tools, l);
	regGlobalVarNoSame(&gTools, "gTools", l);
	regClassFunc(Tools, createUniqueId, l);
	regClassFunc(Tools, getClock, l);
	regClassFunc(Tools, get0Time, l);

	regClassFunc(Tools, getNowTime, l);
	regClassFunc(Tools, getNowYMD, l);
	regClassFunc(Tools, getNowTimeByDate, l);

	regClassFunc(Tools, getDayOfWeek, l);
	regClassFunc(Tools, timestampToString, l);
	regClassFunc(Tools, getMillisTime, l);
	regClassFunc(Tools, getStringTime, l);


	regClass(Timer, l);
	regGlobalVarNoSame(&gTimer, "gTimer", l);
	regClassFunc(Timer, add, l);
	regClassFunc(Timer, del, l);

	regClass(Filter, l);
	regGlobalVarNoSame(&gFilter, "gFilter", l);
	regClassFunc(Filter, add, l);
	regClassFunc(Filter, filterChat, l);
	regClassFunc(Filter, initFailPoint, l);
	regClassFunc(Filter, filterName, l);



	regClass(MainThread, l);
	regGlobalVarNoSame(&gMainThread, "gMainThread", l);
	regClassFunc(MainThread, sendMessage2GameClient, l);
	regClassFunc(MainThread, parseProto, l);
	regClassFunc(MainThread, cacheMessage, l);

	regClassFunc(MainThread, getLogicSessionId, l);
	regClassFunc(MainThread, sendMessage2Master, l);
	regClassFunc(MainThread, saveGlobalData, l);
	regClassFunc(MainThread, sendMessage2GateClient, l);
	regClassFunc(MainThread, forceCloseSession, l);
	regClassFunc(MainThread, getLogicServerList, l);
	regClassFunc(MainThread, getMessageCnt, l);
	regClassFunc(MainThread, removeAccountByAccount, l);

	regClassFunc(MainThread, save, l);
	regClassFunc(MainThread, coreDump, l);
	regClassFunc(MainThread, setEnterCnt, l);
	regClassFunc(MainThread, checkNetworkConnection, l);

	regClassFunc(MainThread, sendMessage2Http, l);	

	regClass(PlayerMgr, l);
	regGlobalVarNoSame(&gPlayerMgr, "gPlayerMgr", l);
	regClassFunc(PlayerMgr, getPlayerById, l);
	regClassFunc(PlayerMgr, getOnlinePlayers, l);
	regClassFunc(PlayerMgr, getOnlineCnt, l);
	regClassFunc(PlayerMgr, regPlayerBaseInfo2Master, l);
	regClassFunc(PlayerMgr, changePlayerName, l);
	regClassFunc(PlayerMgr, updatePlayerBaseInfo2Master, l);
	regClassFunc(PlayerMgr, fakeLoad, l);
	regClassFunc(PlayerMgr, getFakeList, l);

	

	regClass(Player, l);
	regClassFunc(Player, getSessionId, l);
	regClassFunc(Player, getCsessionId, l);
	regClassFunc(Player, getPid, l);
	regClassFunc(Player, setLevel, l);
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
	regClassFunc(Player, setBanTime, l);
	regClassFunc(Player, setBanReason, l);
	regClassFunc(Player, getFromServerId, l);
	regClassFunc(Player, getTitle, l);
	regClassFunc(Player, getAccount, l);
	regClassFunc(Player, getSkin, l);
	regClassFunc(Player, getHeadIcon, l);
	regClassFunc(Player, setName, l);
	regClassFunc(Player, getGmLevel, l);
	regClassFunc(Player, setGmLevel, l);	
	regClassFunc(Player, saveBaseData, l);
	regClassFunc(Player, isZeroTimeLogin, l);
	regClassFunc(Player, saveModuleData, l);	
	regClassFunc(Player, addChargeVal, l);
	regClassFunc(Player, setGuildId, l);

	regClass(RankMgr, l);
	regGlobalVarNoSame(&gRankMgr, "gRankMgr", l);
	regClassFunc(RankMgr, getRank, l);
	regClassFunc(RankMgr, delRank, l);
	regClassFunc(RankMgr, save, l);

	regClass(RankItem, l);
	regClassFunc(RankItem, getId, l);
	regClassFunc(RankItem, getVal1, l);
	regClassFunc(RankItem, getVal2, l);
	regClassFunc(RankItem, getVal3, l);
	regClassFunc(RankItem, getTime, l);


	regClass(Rank, l);
	regClassFunc(Rank, updateRank, l);
	regClassFunc(Rank, getRanking, l);
	regClassFunc(Rank, getRankItem, l);
	regClassFunc(Rank, getRankItemList, l);
	regClassFunc(Rank, delRankItemByRanking, l);
	regClassFunc(Rank, delRankItemById, l);

	regClass(ParseConfig, l);
	regGlobalVarNoSame(&gParseConfig, "gParseConfig", l);
	regClassFunc(ParseConfig, getMasterServerId, l);
	regClassFunc(ParseConfig, isGameServer, l);
	regClassFunc(ParseConfig, isMasterServer, l);
	regClassFunc(ParseConfig, getMasterIdx, l);
	regClassFunc(ParseConfig, getServerId, l);
	regClassFunc(ParseConfig, isDaemon, l);
	regClassFunc(ParseConfig, isDevelopServer, l);






	// regClass(FightMgr, l);
	// regGlobalVarNoSame(&gFightMgr, "gFightMgr", l);
	// regClassFunc(FightMgr, addRandom, l);
	// regClassFunc(FightMgr, addSeq, l);
	// regClassFunc(FightMgr, checkAndPack, l);

}
