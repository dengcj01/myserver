
#include <memory>
#include <string>
#include <unordered_map>
#include "../player/Player.h"
#include "../player/PlayerMgr.h"
#include "../../../common/pb/Login.pb.h"
#include "../../../common/pb/Player.pb.h"
#include "../../../common/CommDefine.h"
#include "../../../common/log/Log.h"
#include "../../../common/ParseConfig.hpp"
#include "../../../common/Timer.hpp"
#include "../../../common/Tools.hpp"
#include "../../../common/Filter.hpp"
#include "../../../common/LoadPlayerData.hpp"
#include "../MainThread.h"
#include "../script/Script.h"
#include "../../../common/pb/Server.pb.h"
#include "../../../common/ProtoIdDef.h"



void reqLoginAuth(uint64_t sessionId, uint64_t csessionId, char *data, size_t len)
{
    ReqLoginAuth req;
    req.ParseFromArray(data, len);

    if(gMainThread.cnt_ > 0)
    {
        uint8_t nowCnt = gPlayerMgr.getOnlineCnt();
        if(nowCnt >= gMainThread.cnt_)
        {
            logInfo("-------------------------------------------set max cnt------------------------------------");
            return;
        }
    }

    int serverId = req.serverid();
    if (gParseConfig.serverId_ != serverId)
    {
        logInfo("reqLoginAuth serverid err %d %d", gParseConfig.serverId_, serverId);
        std::unique_ptr<ResLoginAuth> rsp(std::make_unique<ResLoginAuth>());
        rsp->set_code(ServerErrorCode::NoMatch);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResLoginAuth", std::move(rsp));
        return;
    }


    const std::string account = req.account();
    if(account.empty())
    {
        logInfo("reqLoginAuth empty %s", account.data());
        std::unique_ptr<ResLoginAuth> rsp(std::make_unique<ResLoginAuth>());
        rsp->set_code(ServerErrorCode::AccountIllegal);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResLoginAuth", std::move(rsp));
        return;            
    }


    if(gTools.startAndEndhaveSpace(account))
    {
        logInfo("reqLoginAuth have space %s", account.data());
        std::unique_ptr<ResLoginAuth> rsp(std::make_unique<ResLoginAuth>());
        rsp->set_code(ServerErrorCode::AccountIllegal);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResLoginAuth", std::move(rsp));
        return;        
    }

    if(!gTools.isValidString(account))
    {
        logInfo("reqLoginAuth ServerErrorCode::AccountIllegal %s", account.data());
        std::unique_ptr<ResLoginAuth> rsp(std::make_unique<ResLoginAuth>());
        rsp->set_code(ServerErrorCode::AccountIllegal);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResLoginAuth", std::move(rsp));
        return;        
    }

    const std::string pf = req.pf();
    uint16_t fromServerId = req.fromserverid();

    std::string accountKey = gMainThread.createAccountKey(account, pf, serverId);
    uint64_t oldcessionId = gMainThread.accountIsOnline(accountKey);
    Account* ac = gMainThread.getAccount(oldcessionId);

    if (oldcessionId > 0 && ac)
    {
        gMainThread.forceCloseSession(ac->sessionId_, ac->csessionId_, ExtrusionLine);
    }


    gMainThread.accountList_.emplace(accountKey, csessionId);
    gMainThread.accountData_.emplace(csessionId, Account(account, pf, fromServerId, serverId, sessionId, csessionId));
    ac = gMainThread.getAccount(csessionId);
    ac->step_ = 1;


    std::unique_ptr<ResLoginAuth> rsp(std::make_unique<ResLoginAuth>());

    rsp->set_code(ServerErrorCode::Success);
    gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResLoginAuth", std::move(rsp));
    logInfo("ResLoginAuth success auth account:%s pf:%s fromServerId:%d oldcessionId:%llu", account.data(), pf.data(), fromServerId, oldcessionId);


}

void reqSelectPlayer(uint64_t sessionId, uint64_t csessionId, char *data, size_t len)
{
    Account *ac = gMainThread.getAccount(csessionId);
    if (!ac)
    {
        logInfo("reqSelectPlayer no find csessionId %llu", csessionId);
        std::unique_ptr<ResSelectPlayer> rsp(std::make_unique<ResSelectPlayer>());
        rsp->set_code(ServerErrorCode::NoAuth);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResSelectPlayer", std::move(rsp));
        return;
    }

    if(ac->step_ != 1)
    {
        logInfo("reqSelectPlayer setp err %d", ac->step_);
        std::unique_ptr<ResSelectPlayer> rsp(std::make_unique<ResSelectPlayer>());
        rsp->set_code(ServerErrorCode::NoAuth);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResSelectPlayer", std::move(rsp));        
    }


    ReqDbSelectPlayer db;

    db.set_fromserverid(ac->fromServerId_);
    db.set_account(ac->account_);
    db.set_pf(ac->pf_);
    db.set_csessionid(csessionId);
    db.set_sessionid(sessionId);
    gMainThread.sendMessage2DbServer(db, (uint16_t)ProtoIdDef::ReqDbSelectPlayer);
    logInfo("reqSelectPlayer sess:%llu", csessionId);
}

void reqSelectPlayerDbReturn(char *data, size_t len)
{
    ResDbSelectPlayer res;
    res.ParseFromArray(data, len);

    uint64_t csessionId = res.csessionid();
    Account* ac = gMainThread.getAccount(csessionId);
    
    if (!ac)
    {
        logInfo("reqSelectPlayerDbReturn no csessionId %llu", csessionId);
        return;
    }

    uint64_t pid = res.pid();
    int code = res.code();

    if(code == ServerErrorCode::Success)
    {
        if(pid > 0)
        {
            ac->pid_ = pid;
        }
        ac->step_ = 2;
    }

    std::unique_ptr<ResSelectPlayer> rsp(std::make_unique<ResSelectPlayer>());
    rsp->set_code(code);
    rsp->set_pid(pid);

    gMainThread.sendMessage2GateClient(res.sessionid(), csessionId, "ResSelectPlayer", std::move(rsp));

    logInfo("reqSelectPlayerDbReturn sess:%llu code:%d", csessionId, code);
}


void reqCreatePlayer(uint64_t sessionId, uint64_t csessionId, char *data, size_t len)
{
    Account *ac = gMainThread.getAccount(csessionId);
    if (!ac)
    {
        logInfo("reqCreatePlayer no find csessionId %llu", csessionId);
        std::unique_ptr<ResCreatePlayer> rsp(std::make_unique<ResCreatePlayer>());
        rsp->set_code(ServerErrorCode::NoAuthCreate);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResCreatePlayer", std::move(rsp));
        return;
    }

    if(ac->step_ != 2)
    {
        logInfo("reqCreatePlayer no find csessionId %llu", csessionId);
        std::unique_ptr<ResCreatePlayer> rsp(std::make_unique<ResCreatePlayer>());
        rsp->set_code(ServerErrorCode::NoAuthCreate);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResCreatePlayer", std::move(rsp));
        return;
    }

    if(ac->pid_ > 0)
    {
        logInfo("reqCreatePlayer have pid sess:%llu pid:%llu", csessionId, ac->pid_);
        std::unique_ptr<ResCreatePlayer> rsp(std::make_unique<ResCreatePlayer>());
        rsp->set_code(ServerErrorCode::HavePidCreate);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResCreatePlayer", std::move(rsp));
        return;
    }


    ReqCreatePlayer req;
    req.ParseFromArray(data, len);

    uint32_t sex = req.sex();
    const std::string &name = req.name();


    if (!name.empty())
    {
        std::string ret = gFilter.filterName(name.data());
        if(ret.empty())
        {
            logInfo("reqCreatePlayer filter sess:%llu name:%s", csessionId, name.data());
            std::unique_ptr<ResCreatePlayer> rsp(std::make_unique<ResCreatePlayer>());
            rsp->set_code(ServerErrorCode::NameError);
            gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResCreatePlayer", std::move(rsp));         
            return;   
        }

        if(name.size() > 20)
        {
            logInfo("reqCreatePlayer ServerErrorCode::NameToLongError name sess:%llu", csessionId);
            std::unique_ptr<ResCreatePlayer> rsp(std::make_unique<ResCreatePlayer>());
            rsp->set_code(ServerErrorCode::NameToLongError);
            gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResCreatePlayer", std::move(rsp));         
            return;               
        }

        ReqDbCreatePlayer db;
        db.set_fromserverid(ac->fromServerId_);
        db.set_account(ac->account_);
        db.set_pf(ac->pf_);
        db.set_csessionid(csessionId);
        db.set_sessionid(sessionId);

        db.set_name(name);
        db.set_sex(sex);
        db.set_serverid(gParseConfig.serverId_);
        db.set_pid(gTools.createUniqueId());
        //db.set_pid(1001);

        gMainThread.sendMessage2DbServer(db, (uint16_t)ProtoIdDef::ReqDbCreatePlayer);   
        logInfo("reqCreatePlayer sess:%llu", csessionId);

    }


}

void reqCreatePlayerDbReturn(char *data, size_t len)
{
    ResDbCreatePlayer res;
    res.ParseFromArray(data, len);

    uint64_t csessionId = res.csessionid();

    Account *ac = gMainThread.getAccount(csessionId);
    if (!ac)
    {
        logInfo("reqCreatePlayerDbReturn no csessionId %llu", csessionId);
        return;
    }

    int code = res.code();
    uint64_t pid = res.pid();
    if(code == 0 && pid > 0)
    {
        ac->pid_ = pid;
    }

    std::unique_ptr<ResCreatePlayer> rsp(std::make_unique<ResCreatePlayer>());
    rsp->set_code(code);
    rsp->set_pid(pid);
    rsp->set_name(res.name());
    rsp->set_sex(res.sex());
    gMainThread.sendMessage2GateClient(res.sessionid(), csessionId, "ResCreatePlayer", std::move(rsp));

    logInfo("reqCreatePlayerDbReturn sess:%llu pid:%llu code:%d", csessionId, pid, code);
}



void reqEnterGame(uint64_t sessionId, uint64_t csessionId, char *data, size_t len)
{
    Account *ac = gMainThread.getAccount(csessionId);
    if (!ac)
    {
        logInfo("reqEnterGame no find csessionId %llu", csessionId);
        std::unique_ptr<ResLoginAuth> rsp(std::make_unique<ResLoginAuth>());
        rsp->set_code(ServerErrorCode::NoAuthEnter);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResEnterGame", std::move(rsp));
        return;
    }

    if(ac->pid_ <= 0)
    {
        logInfo("reqEnterGame no reg pid sess:%llu", csessionId);
        std::unique_ptr<ResLoginAuth> rsp(std::make_unique<ResLoginAuth>());
        rsp->set_code(ServerErrorCode::NoRegEnterGame);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResEnterGame", std::move(rsp));
        return;        
    }

    ReqEnterGame req;
    req.ParseFromArray(data, len);

    uint64_t pid = req.pid();


    ReqDbEnterGame db;
    db.set_pid(pid);
    db.set_csessionid(csessionId);
    db.set_sessionid(sessionId);    
    logInfo("reqEnterGame sess:%llu pid:%llu", csessionId, pid);
    gMainThread.sendMessage2DbServer(db, (uint16_t)ProtoIdDef::ReqDbEnterGame);
}



void resReturnPlayerBaseData(char *data, size_t len)
{
    ResReturnPlayerBaseData res;
    res.ParseFromArray(data, len);

    uint64_t csessionId = res.csessionid();

    if (!gMainThread.getAccount(csessionId))
    {
        logInfo("resReturnPlayerBaseData no csessionId %llu", csessionId);
        return;
    }

    uint64_t sessionId = res.sessionid();
    Player *player = gPlayerMgr.getPlayer(csessionId);
    if (player)
    {
        logInfo("resReturnPlayerBaseData have player %llu", csessionId);         
        return;
    }

    uint64_t pid = res.pid();
    

    player = gPlayerMgr.newPlayer(sessionId, csessionId, pid);

    player->initBaseData(res.data());


}



void resReturnPlayerModuleData(char *data, size_t len)
{

    ResReturnPlayerModuleData res;
    res.ParseFromArray(data, len);

    uint64_t csessionId = res.csessionid();

    if (!gMainThread.getAccount(csessionId))
    {
        logInfo("resReturnPlayerModuleData no csessionId %llu", csessionId);
        return;
    }

    Player *player = gPlayerMgr.getPlayer(csessionId);
    if (!player)
    {
        logInfo("resReturnPlayerModuleData no player %llu", csessionId);        
        return;
    }

    uint64_t pid = player->getPid();
    uint8_t moduleId = res.moduleid();
    if(!gPlayerMgr.isFakeLoad(pid, moduleId))
    {
        player->initModuleData(moduleId, res.data());
    }
}

void reqEnterGameDbReturn(char *data, size_t len)
{
    ResDbEnterGame res;
    res.ParseFromArray(data, len);
    uint64_t csessionId = res.csessionid();

    if (!gMainThread.getAccount(csessionId))
    {
        logInfo("reqEnterGameDbReturn no csessionId");
        return;
    }

    int code = res.code();
    uint64_t pid = res.pid();
    uint64_t sessionId = res.sessionid();

    Player *player = gPlayerMgr.getPlayer(csessionId);


    logInfo("reqEnterGameDbReturnreqEnterGameDbReturn %d", code);

    if (code > 0)
    {
        logInfo("reqEnterGameDbReturn err %llu", code);
        gMainThread.removeAccount(csessionId);
        gPlayerMgr.playerLogout(player, false);
        gPlayerMgr.removePlayerById(pid);
		gPlayerMgr.removePlayerBySessionId(csessionId);
        std::unique_ptr<ResEnterGame> rsp(std::make_unique<ResEnterGame>());
        rsp->set_code(code);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResEnterGame", std::move(rsp));

        gPlayerMgr.cleanPlayerLuaModuleData(pid);
        return;
    }

    if(!player)
    {
        logInfo("reqEnterGameDbReturn no player %llu", csessionId);
        return;        
    }


    gPlayerMgr.addPlayerById(pid, player);
    gPlayerMgr.playerLogin(player);

    std::unique_ptr<ResEnterGame> rsp(std::make_unique<ResEnterGame>());
    rsp->set_code(0);
    logInfo("playerLogin success pid:%llu sess:%llu", pid, csessionId);

    gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResEnterGame", std::move(rsp));
    //player->notifyPlayerBaseData(sessionId, csessionId);

    LuaBind::CallLua cl1(gScript.l, "gCheckHaveThisPlayer", 1);
    bool ok = cl1.call<bool, void>(pid);
    if(!ok)
    {
        gPlayerMgr.regPlayerBaseInfo2Master(player);
    }
    else
    {
        
    }


}


void resDbUpdatePlayerName(char *data, size_t len)
{
    ResDbUpdatePlayerName res;
    res.ParseFromArray(data, len);

    LuaBind::CallLua cl(gScript.l, "gDbChangeNameRet");
    cl.call<void, void>(res.pid(), res.code(), res.name()); 
}

typedef void (*FunctionPtr)(uint64_t, uint64_t, char *, size_t);
void dispatchGateClientMessage(uint64_t sessionId, uint16_t messageId, uint64_t csessionId, char *data, size_t len)
{
    logInfo("dispatchGateClientMessage %d", messageId);
    FunctionPtr func = gMainThread.getProtoFunc(messageId);
    if(func)
    {
        func(sessionId, csessionId, data, len);
    }
}


void notifyCloseGame(uint64_t sessionId, char *data, size_t len)
{
    gMainThread.onClose();
}

void reqUpdatePlayerBaseInfo(uint64_t sessionId, char *data, size_t len)
{
    ReqUpdatePlayerBaseInfo rp;
    rp.ParseFromArray(data, len);

    uint64_t pid = rp.pid();
    std::string s = rp.data();

    LuaBind::CallLua cl(gScript.l, "gUpdatePlayerBaseInfo");
    cl.call<void, void>(pid, s);  

    gMainThread.sendMessage2DbServer(rp, (uint16_t)ProtoIdDef::ReqUpdatePlayerBaseInfo);

}

void reqRegPlayerBaseInfo(uint64_t sessionId, char *data, size_t len)
{
    PlayerBaseData rd;
    rd.ParseFromArray(data, len);

    gMainThread.sendMessage2DbServer(rd, (uint16_t)ProtoIdDef::ReqRegPlayerBaseInfo);

    const nlohmann::json& j = packPlayerBaseData2Json(rd);

    std::string s = j.dump();
    LuaBind::CallLua cl(gScript.l, "gRegPlayerBaseInfo");
    cl.call<void, void>(s);  
}


typedef void (*FunctionPtr1)(uint64_t, char *, size_t);
void dispatchGameClientMessage(uint16_t messageId, uint64_t sessionId, char *data, size_t len)
{
    logInfo("dispatchGameClientMessage %d", messageId);
    FunctionPtr1 func = gMainThread.getProtoFunc1(messageId);
    if(func)
    {
        func(sessionId, data, len);
    }
}


void dispatchDbServerMessage(uint16_t messageId, char *data, size_t len)
{
    //logInfo("dispatchDbServerMessage %d", messageId);
    switch (messageId)
    {
    case (uint16_t)ProtoIdDef::ResDbSelectPlayer:
        reqSelectPlayerDbReturn(data, len);
        break;
    case (uint16_t)ProtoIdDef::ResDbCreatePlayer:
        reqCreatePlayerDbReturn(data, len);
        break;
    case (uint16_t)ProtoIdDef::ResReturnPlayerBaseData:
        resReturnPlayerBaseData(data, len);
        break;
    case (uint16_t)ProtoIdDef::ResReturnPlayerModuleData:
        resReturnPlayerModuleData(data, len);
        break;
    case (uint16_t)ProtoIdDef::ResDbEnterGame:
        reqEnterGameDbReturn(data, len);
        break;        
    case (uint16_t)ProtoIdDef::ResDbUpdatePlayerName:
        resDbUpdatePlayerName(data, len);
        break;
    default:
        break;
    }
}


