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
//#include "../../../../libs/jemalloc/jemalloc.h"
#include "../script/Script.h"
#include "../../../common/Timer.hpp"
#include "../../../common/LoadPlayerData.hpp"
#include "../../../common/Tools.hpp"
#include "../../../common/pb/Server.pb.h"
#include "../../../common/pb/Player.pb.h"

#include "../../../common/ProtoIdDef.h"
#include <string_view>



PlayerMgr::~PlayerMgr()
{
}

void PlayerMgr::closeAllPlayer(uint8_t useDb)
{
    for (auto& e:playerList_)
    {
        Player* player = e.second;
        playerLogout(player, true, useDb);
        usleep(10000);
    }
    playerList_.clear();
    playerIdList_.clear();


    logInfo("closeAllPlayer %d %d", playerIdList_.size(), playerIdList_.size());
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




void PlayerMgr::playerLogout(Player *player, bool save, uint8_t useDb)
{
    if (!player)
    {
        return;
    }

    uint64_t pid = player->getPid();

    if (save)
    {
        LuaBind::CallLua cl(gScript.l, "gLogout");
        cl.call<void, void>(player, pid, gTools.getNowTime());
        player->saveData(useDb);
    }

    uint64_t csessionId = player->csessionId_;

    delete player;
    player = nullptr;
    logInfo("playerLogout %llu %llu", pid, csessionId);
}



void PlayerMgr::playerLogin(Player *player)
{
    uint32_t curTime = gTools.getNowTime();
    bool first = player->firstLoginTime_ <= 0;
    bool newDay = false;
    int day = 0;
    uint64_t pid = player->getPid();

    removeFakePlayer(pid);

    if (!first && player->logoutTime_ > 0)
    {

        day = gTools.getDiffDay(curTime, player->logoutTime_);
        if(day > 0)
        {
            if(day > 1)
            {
                newDay = true;
            }
            else
            {
                uint32_t newDayTime = gTools.get0Time(curTime) + 14400;
                if(curTime >= newDayTime)
                {
                    logInfo("------playerLogin newday1 pid:%llu now:%s last:%s", pid, gTools.timestampToString(curTime).data(), gTools.timestampToString(player->logoutTime_).data());
                    newDay = true;
                }
            }
        }
        else
        {
            uint32_t newDayTime = gTools.get0Time(curTime) + 14400;
            if(curTime >= newDayTime && player->logoutTime_ < newDayTime)
            {
                logInfo("------playerLogin newday2 pid:%llu now:%s last:%s", pid, gTools.timestampToString(curTime).data(), gTools.timestampToString(player->logoutTime_).data());
                newDay = true;
            }          
        }

    }

    //logInfo("playerLoginplayerLoginplayerLoginplayerLoginplayerLogin pid:%llu, flag:%d day:%d", player->pid_, newDay, day);
    

    player->loginTime_ = curTime;


    LuaBind::CallLua cl(gScript.l, "gLogin");
    cl.call<void, void>(player, pid, curTime, first);

    //logInfo("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
    

    if (newDay)
    {
        LuaBind::CallLua cl1(gScript.l, "gNewDay");
        cl1.call<void, void>(player, pid, curTime);
        
        std::string strTime = gTools.getStringTime(curTime);
        std::string_view vs = strTime;
        std::string_view res = vs.substr(12, 13);
        if (res == "00")
        {
            player->zeroTimeLogin_ = true;
        }
    }
    
    //logInfo("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1111111111111111111111111");
    
    player->save();

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


void PlayerMgr::cleanPlayerLuaModuleData(uint64_t pid)
{
    LuaBind::CallLua cl(gScript.l, "gRemoveAllModuleData");
    cl.call<void, void>(pid);       
}


void PlayerMgr::regPlayerBaseInfo2Master(Player* player)
{
    PlayerBaseData rd;

    rd.set_pid(player->getPid());
    rd.set_name(player->getName());
    rd.set_account(player->getAccount());
    rd.set_level(player->getLevel());
    rd.set_serverid(gParseConfig.serverId_);
    rd.set_vip(player->getVip());
    rd.set_icon(player->getIcon());
    rd.set_title(player->getTitle());
    rd.set_headicon(player->getHeadIcon());
    rd.set_skin(player->getSkin());
    rd.set_power(player->getPower());
    rd.set_guildid(player->getGuildId());
    rd.set_sex(player->getSex());

    const nlohmann::json& j = packPlayerBaseData2Json(rd);

    std::string s = j.dump();
    LuaBind::CallLua cl(gScript.l, "gRegPlayerBaseInfo");
    cl.call<void, void>(s);  

    gMainThread.sendMessage2MasterServer(rd, (uint16_t)ProtoIdDef::ReqRegPlayerBaseInfo);
}

void PlayerMgr::updatePlayerBaseInfo2Master(uint64_t pid, const char* str)
{
    ReqUpdatePlayerBaseInfo rd;
    rd.set_data(str);
    rd.set_pid(pid);

    ReqUpdatePlayerBaseInfo rd1;
    rd1.set_data(str);
    rd1.set_pid(pid);

    gMainThread.sendMessage2DbServer(rd, (uint16_t)ProtoIdDef::ReqUpdatePlayerBaseInfo);

    gMainThread.sendMessage2MasterServer(rd1, (uint16_t)ProtoIdDef::ReqUpdatePlayerBaseInfo);
}



void PlayerMgr::changePlayerName(Player* player, const char* name)
{
    if(!player)
    {
        logInfo("changePlayerName no player");
        return;
    }

    ReqDbUpdatePlayerName db;

    db.set_name(name);
    db.set_pid(player->getPid());

    gMainThread.sendMessage2DbServer(db, (uint16_t)ProtoIdDef::ReqDbUpdatePlayerName);  
}

void PlayerMgr::removeFakePlayer(uint64_t pid)
{
    auto it = fakeList_.find(pid);
    if(it != fakeList_.end())
    {
        Player* player = it->second;
        delete player;
        player = nullptr;
        fakeList_.erase(it);
    }
    
    fakeModuleList_.erase(pid);
}

bool PlayerMgr::isFakeLoad(uint64_t pid, uint8_t moduleId)
{
    auto it = fakeModuleList_.find(pid);
    if(it == fakeModuleList_.end())
    {
        return false;
    }
    
    auto& mapList = it->second;
    return mapList.find(moduleId) != mapList.end();
}

Player *PlayerMgr::fakeLoad(uint64_t pid, uint8_t moduleId)
{
    auto it = fakeList_.find(pid);
    Player* player = nullptr;
    if(it == fakeList_.end())
    {
        player = new Player;
        player->pid_ = pid;
        fakeList_.emplace(pid, player);
    }
    else
    {
        player = it->second;
    }

    auto listModule = fakeModuleList_.find(pid);
    if(listModule == fakeModuleList_.end())
    {   
        std::string data;
        uint8_t code = loadPlayerOneModuleData(pid, moduleId, data);
    
        if(code == 0)
        {
            LuaBind::CallLua cl(gScript.l, "gLoadPlayerModuleData");
            cl.call<void, void>(pid, moduleId, data);
            fakeModuleList_.emplace(pid, std::unordered_map<uint8_t, uint8_t>{{moduleId, 1}});
        }
    }
    else
    {
        auto& mapModule = listModule->second;
        if(mapModule.find(moduleId) == mapModule.end())
        {
            std::string data;
            uint8_t code = loadPlayerOneModuleData(pid, moduleId, data);
        
            if(code == 0)
            {
                LuaBind::CallLua cl(gScript.l, "gLoadPlayerModuleData");
                cl.call<void, void>(pid, moduleId, data);
                mapModule.emplace(moduleId, 1);
            }
        }
    }


    return player;
}