#include "PlayerMgr.h"
#include "Player.h"
#include "../MainThread.h"
#include "../../../common/MysqlClient.h"
#include "../../../common/log/Log.h"
#include "../../../../libs/mysql/mysql_connection.h"
#include "../../../../libs/mysql/mysql_error.h"
#include "../../../../libs/mysql/cppconn/resultset.h"
#include "../../../../libs/mysql/cppconn/statement.h"
#include "../../../../libs/mysql/cppconn/prepared_statement.h"
#include "../../../../libs/jemalloc/jemalloc.h"
#include "../script/Script.h"
#include "../../../common/Timer.hpp"
#include "../../../common/LoadPlayerData.hpp"
#include "../../../common/Tools.hpp"
#include <string_view>

PlayerMgr::~PlayerMgr()
{
}

void PlayerMgr::closeAllPlayer()
{
    cleanZeroList();
    fakePlayerList_.clear();
    for (auto &e : playerList_)
    {
        playerLogout(e.second, true, false);
    }
}

Player *PlayerMgr::newPlayer(uint64_t sessionId, uint64_t csessionId, uint64_t pid)
{
    Player *player = new Player();
    player->sessionId_ = sessionId;
    player->csessionId_ = csessionId;
    player->pid_ = pid;
    playerList_.emplace(csessionId, player);
    return player;
}

Player *PlayerMgr::getPlayer(uint64_t sessionId)
{
    auto it = playerList_.find(sessionId);
    if (it == playerList_.end())
    {
        return nullptr;
    }
    return it->second;
}

Player *PlayerMgr::fakeLogin(uint64_t pid)
{
    auto it = fakePlayerList_.find(pid);
    if (it != fakePlayerList_.end())
    {
        return it->second;
    }

    Player *player = new Player();
    player->pid_ = pid;
    fakePlayerList_.emplace(pid, player);

    PlayerBaseData pd;
    loadPlayerBaseData(pid, pd);
    player->initBaseData(pd);

    ResReturnPlayerBagData res;
    loadPlayerBagData(pid, res);
    player->initBagData(res);

    Args *args = (Args *)je_malloc(sizeof(Args));
    args->pid_ = pid;
    player->timeId_ = gTimer.add(gTools.random(60, 120), &PlayerMgr::fakeLoginCallback, args);
    return player;
}

void PlayerMgr::fakeLoginCallback(Args *args)
{
    uint64_t pid = args->pid_;
    Player *player = gPlayerMgr.getFakePlayer(args->pid_);
    if (!player)
    {
        return;
    }

    if (gMainThread.isInEnter(pid))
    {
        return;
    }

    gPlayerMgr.saveFakePlayerData(pid);
    gPlayerMgr.releaseFakePlayer(player);
}

std::vector<std::string> PlayerMgr::loadFakePlayerData(uint64_t pid, uint8_t moduleId)
{
    std::vector<std::string> vec;
    auto it = fakePlayerList_.find(pid);
    if (it == fakePlayerList_.end())
    {
        return vec;
    }

    Player *player = it->second;
    if (!player->canFakeLoad(moduleId))
    {
        return vec;
    }

    sql::PreparedStatement *ps = nullptr;
    try
    {
        ps = gMysqlClient.getMysqlCon()->prepareStatement(queryplayermodule);
        ps->setUInt64(1, pid);
        ps->setInt(2, moduleId);
        sql::ResultSet *rst = ps->executeQuery();
        while (rst->next())
        {
            vec.emplace_back(rst->getString("data").asStdString());
            player->addFakeModuleId(moduleId);
        }
        delete rst;
        ps->getMoreResults();
        delete ps;
    }
    catch (sql::SQLException &e)
    {
        logInfo(e.what());
    }

    return vec;
}

void PlayerMgr::playerLogout(Player *player, bool save, bool db)
{
    if (!player)
    {
        return;
    }

    uint64_t pid = player->getPid();
    gMainThread.resetEnter(pid);

    if (save)
    {
        LuaBind::CallLua cl(gScript.l, "gLogout");
        cl.call<void, void>(player, time(0));
        player->saveData(db);
    }

    uint64_t csessionId = player->csessionId_;

    removePlayer(csessionId);
    removePlayerById(pid);

    delete player;
    player = nullptr;
    logInfo("playerLogout %llu %d %d", pid, save, db);
}

void PlayerMgr::playerLogin(Player *player)
{
    uint32_t curTime = time(0);
    LuaBind::CallLua cl(gScript.l, "gLogin");
    bool first = player->loginTime_ > 0 ? false : true;
    bool newDay = false;
    if (!first && curTime >= (gTools.get0Time(player->loginTime_) + 86400))
    {
        newDay = true;
    }

    player->loginTime_ = curTime;
    cl.call<void, void>(player, first, curTime);
    uint64_t pid = player->getPid();
    if (newDay)
    {
        LuaBind::CallLua cl1(gScript.l, "gNewDay");
        cl1.call<void, void>(player, curTime);
        std::string strTime = gTools.getStringTime(curTime);
        std::string_view vs = strTime;
        std::string_view res = vs.substr(12, 13);
        if (res == "00")
        {
            zeroList_.emplace(pid, 1);
        }
    }
    logInfo("playerLogin %llu", pid);
}

Player *PlayerMgr::getFakePlayer(uint64_t pid)
{
    auto it = fakePlayerList_.find(pid);
    if (it == fakePlayerList_.end())
    {
        return 0;
    }
    return it->second;
}

void PlayerMgr::releaseFakePlayer(Player *player)
{
    if (player)
    {
        player->fakeModuleIdList_.clear();

        uint64_t pid = player->pid_;
        delete player;
        player = nullptr;

        fakePlayerList_.erase(pid);
    }
}

Player *PlayerMgr::getPlayerById(uint64_t pid)
{
    auto it = playerIdList_.find(pid);
    if (it == playerIdList_.end())
    {
        return 0;
    }

    return it->second;
}

void PlayerMgr::saveFakePlayerData(uint64_t pid)
{
    if (pid > 0)
    {
        Player::saveModuleData(pid, 3);
    }
}

void PlayerMgr::savePlayerModuleData(uint64_t pid)
{
    Player::saveModuleData(pid, 1);
}

void PlayerMgr::testLoad()
{
    uint64_t s = gTools.getMillisTime();
    std::map<uint8_t, std::string> mdata;
    loadPlayerModuleData(1, mdata);
    for (auto &e : mdata)
    {
        uint8_t moduleId = e.first;
        LuaBind::CallLua cl1(gScript.l, "gLoadPlayerModuleData");
        cl1.call<void, void>(1, moduleId, e.second);
    }

    logInfo("-------------------%lu", gTools.getMillisTime() - s);
}

void PlayerMgr::testSave()
{
    uint64_t s = gTools.getMillisTime();
    LuaBind::CallLua cl(gScript.l, "gGetPlayerModuleData");
    std::map<uint8_t, const char *> datas = cl.call<std::map<uint8_t, const char *>, void>(1, 3);
    uint16_t serverId = gParseConfig.serverId_;
    for (auto &e : datas)
    {
        sql::PreparedStatement *ps = nullptr;
        try
        {
            ps = gMysqlClient.getMysqlCon()->prepareStatement("replace into actormodule(pid,moduleid,data,serverid)values(?,?,?,?)");
            ps->setUInt64(1, 1);
            ps->setInt(2, e.first);
            ps->setString(3, e.second);
            ps->setInt(4, serverId);
            ps->execute();
            delete ps;

        }
        catch (sql::SQLException &e)
        {
            logInfo(e.what());
        }
    }
    logInfo("-------------------%lu", gTools.getMillisTime() - s);
}

void PlayerMgr::cleanPlayerLuaModuleData(uint64_t pid)
{
    LuaBind::CallLua cl(gScript.l, "gRemoveAllModuleData");
    cl.call<void, void>(pid);       
}