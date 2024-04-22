
#include <memory>
#include <string>
#include <unordered_map>
#include "../player/Player.h"
#include "../player/PlayerMgr.h"
#include "../pb/Login.pb.h"

#include "../../../common/CommDefine.h"
#include "../../../common/pb/ServerCommon.pb.h"
#include "../../../common/log/Log.h"
#include "../../../common/ParseConfig.hpp"
#include "../../../common/Timer.hpp"
#include "../../../common/Tools.hpp"
#include "../../../common/LoadPlayerData.hpp"
#include "../MainThread.h"
#include "../script/Script.h"


void reqLoginAuth(uint64_t sessionId, uint64_t csessionId, char *data, size_t len)
{
    ReqLoginAuth req;
    req.ParseFromArray(data, len);

    if (gParseConfig.serverId_ != req.serverid())
    {
        logInfo("reqLoginAuth serverid err %d %d", gParseConfig.serverId_, req.serverid());
        std::unique_ptr<ResLoginAuth> rsp(std::make_unique<ResLoginAuth>());
        rsp->set_code(servernomath);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResLoginAuth", std::move(rsp));
        return;
    }

    const std::string account = req.account();
    const std::string pf = req.pf();
    uint16_t fromServerId = req.fromserverid();

    std::string accountKey = gMainThread.createAccountKey(account, pf, gParseConfig.serverId_);
    uint64_t oldcessionId = gMainThread.accountIsOnline(accountKey);
    Account* ac = gMainThread.getAccount(oldcessionId);

    if (oldcessionId > 0 && ac)
    {
        logInfo("ResLoginAuth err %s %s %d %llu", account.data(), pf.data(), fromServerId, oldcessionId);
        gMainThread.forceCloseSession(ac->sessionId_, ac->csessionId_, SCCRType::SCCRType_ji_hao);


        std::unique_ptr<ResLoginAuth>
            rsp(std::make_unique<ResLoginAuth>());
        rsp->set_code(serverisonline);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResLoginAuth", std::move(rsp));
        return;
    }
    else
    {
        gMainThread.accountList_.emplace(accountKey, csessionId);
        gMainThread.accountData_.emplace(csessionId, Account(account, pf, fromServerId, sessionId, csessionId));
    }

    ReqDbLoginAuth db;
    db.set_fromserverid(fromServerId);
    db.set_account(account);
    db.set_password(req.password());
    db.set_pf(pf);
    db.set_csessionid(csessionId);
    db.set_sessionid(sessionId);

    //logInfo("reqDbLoginAuth %llu %llu", csessionId,sessionId);
    gMainThread.sendMessage2DbServer(db, g2dReqDbLoginAuth);
}

void reqLoginAuthDbReturn(char *data, size_t len)
{
    ResDbLoginAuth res;
    res.ParseFromArray(data, len);


    uint64_t csessionId = res.csessionid();

    //logInfo("reqLoginAuthDbReturn %llu %d",csessionId, res.code());
    if (!gMainThread.getAccount(csessionId))
    {
        logInfo("reqLoginAuthDbReturn no csessionId");
        return;
    }


    std::unique_ptr<ResLoginAuth> rsp(std::make_unique<ResLoginAuth>());
    uint8_t code = res.code();
    rsp->set_code(code);
    gMainThread.sendMessage2GateClient(res.sessionid(), csessionId, "ResLoginAuth", std::move(rsp));
}

void reqSelectPlayer(uint64_t sessionId, uint64_t csessionId, char *data, size_t len)
{
    Account *ac = gMainThread.getAccount(csessionId);
    if (!ac)
    {
        logInfo("reqSelectPlayer no find csessionId");
        std::unique_ptr<ResLoginAuth> rsp(std::make_unique<ResLoginAuth>());
        rsp->set_code(servernoauth);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResLoginAuth", std::move(rsp));
        return;
    }

    ReqDbSelectPlayer db;

    db.set_fromserverid(ac->fromServerId_);
    db.set_account(ac->account_);
    db.set_pf(ac->pf_);
    db.set_csessionid(csessionId);
    db.set_sessionid(sessionId);
    gMainThread.sendMessage2DbServer(db, g2dReqDbSelectPlayer);
}

void reqSelectPlayerDbReturn(char *data, size_t len)
{
    ResDbSelectPlayer res;
    res.ParseFromArray(data, len);

    uint64_t csessionId = res.csessionid();
    if (!gMainThread.getAccount(csessionId))
    {
        logInfo("reqSelectPlayerDbReturn no csessionId");
        return;
    }

    std::unique_ptr<ResSelectPlayer> rsp(std::make_unique<ResSelectPlayer>());
    rsp->set_code(res.code());
    rsp->set_pid(res.pid());

    gMainThread.sendMessage2GateClient(res.sessionid(), csessionId, "ResSelectPlayer", std::move(rsp));
}

void reqCreatePlayer(uint64_t sessionId, uint64_t csessionId, char *data, size_t len)
{
    Account *ac = gMainThread.getAccount(csessionId);
    if (!ac)
    {
        logInfo("reqCreatePlayer no find csessionId");
        std::unique_ptr<ResLoginAuth> rsp(std::make_unique<ResLoginAuth>());
        rsp->set_code(servernoauthcreate);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResLoginAuth", std::move(rsp));
        return;
    }

    ReqCreatePlayer req;
    req.ParseFromArray(data, len);

    ReqDbCreatePlayer db;
    db.set_fromserverid(ac->fromServerId_);
    db.set_account(ac->account_);
    db.set_pf(ac->pf_);
    db.set_csessionid(csessionId);
    db.set_sessionid(sessionId);

    uint32_t sex = req.sex();
    const std::string &name = req.name();
    db.set_name(name);

    if (name.empty())
    {
        db.set_name(gMainThread.randName(sex));
    }

    db.set_sex(sex);
    db.set_serverid(gParseConfig.serverId_);
    db.set_pid(gTools.createUniqueId());

    gMainThread.sendMessage2DbServer(db, g2dReqDbCreatePlayer);
}

void reqCreatePlayerDbReturn(char *data, size_t len)
{
    ResDbCreatePlayer res;
    res.ParseFromArray(data, len);

    uint64_t csessionId = res.csessionid();

    if (!gMainThread.getAccount(csessionId))
    {
        logInfo("reqCreatePlayerDbReturn no csessionId");
        return;
    }

    std::unique_ptr<ResCreatePlayer> rsp(std::make_unique<ResCreatePlayer>());
    rsp->set_code(res.code());
    rsp->set_pid(res.pid());
    rsp->set_name(res.name());
    rsp->set_sex(res.sex());
    gMainThread.sendMessage2GateClient(res.sessionid(), csessionId, "ResCreatePlayer", std::move(rsp));
}

void reqEnterGame(uint64_t sessionId, uint64_t csessionId, char *data, size_t len)
{
    Account *ac = gMainThread.getAccount(csessionId);
    if (!ac)
    {
        logInfo("reqEnterGame no find csessionId");
        std::unique_ptr<ResLoginAuth> rsp(std::make_unique<ResLoginAuth>());
        rsp->set_code(servernoauthenter);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResLoginAuth", std::move(rsp));
        return;
    }

    ReqEnterGame req;
    req.ParseFromArray(data, len);

    uint64_t pid = req.pid();
    ac->status_ = true;
    gMainThread.enter_[pid] = csessionId;
    //logInfo("reqEnterGame %llu", pid);

    ReqDbEnterGame db;
    db.set_pid(pid);
    db.set_csessionid(csessionId);
    db.set_sessionid(sessionId);    

    gMainThread.sendMessage2DbServer(db, g2dReqDbEnterGame);
}

void resReturnPlayerBaseData(char *data, size_t len)
{
    ResReturnPlayerBaseData res;
    res.ParseFromArray(data, len);

    uint64_t csessionId = res.csessionid();

    if (!gMainThread.getAccount(csessionId))
    {
        logInfo("resReturnPlayerBaseData no csessionId");
        return;
    }

    uint64_t sessionId = res.sessionid();
    Player *player = gPlayerMgr.getPlayer(csessionId);
    if (player)
    {
        logInfo("resReturnPlayerBaseData have player");         
        return;
    }

    uint64_t pid = res.pid();

    //logInfo("resReturnPlayerBaseData %llu", pid);

    player = gPlayerMgr.newPlayer(sessionId, csessionId, pid);
    player->initBaseData(res.data());
}

void resReturnPlayerBagData(char *data, size_t len)
{
    ResReturnPlayerBagData res;
    res.ParseFromArray(data, len);
    uint64_t csessionId = res.csessionid();

    if (!gMainThread.getAccount(csessionId))
    {
        logInfo("resReturnPlayerBagData no find csessionId");
        return;
    }

    Player *player = gPlayerMgr.getPlayer(csessionId);
    if (!player)
    {
        logInfo("resReturnPlayerBaseData no player");          
        return;
    }

    player->initBagData(res);
}


void resReturnPlayerModuleData(char *data, size_t len)
{
    ResReturnPlayerModuleData res;
    res.ParseFromArray(data, len);

    uint64_t csessionId = res.csessionid();

    if (!gMainThread.getAccount(csessionId))
    {
        logInfo("resReturnPlayerModuleData no csessionId");
        return;
    }

    Player *player = gPlayerMgr.getPlayer(csessionId);
    if (!player)
    {
        logInfo("resReturnPlayerModuleData no player");        
        return;
    }

    uint64_t pid = player->getPid();
    Player *fakePlayer = gPlayerMgr.getFakePlayer(pid);
    uint8_t moduleId = res.moduleid();
    bool ok = true;

    if (fakePlayer && !fakePlayer->canFakeLoad(moduleId))
    {
        ok = false;
    }
    if (ok)
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
    if (code > 0)
    {
        logInfo("reqEnterGameDbReturn err %llu", code);
        gMainThread.removeAccount(csessionId);
        gPlayerMgr.playerLogout(player, false);
        std::unique_ptr<ResEnterGame> rsp(std::make_unique<ResEnterGame>());
        rsp->set_code(code);
        gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResEnterGame", std::move(rsp));

        gPlayerMgr.cleanPlayerLuaModuleData(pid);
        return;
    }

    if(!player)
    {
        logInfo("reqEnterGameDbReturn no player %llu", csessionId);
        sleep(3);
        return;        
    }

    gPlayerMgr.addPlayerById(pid, player);
    Player *fakePlayer = gPlayerMgr.getFakePlayer(pid);

    gPlayerMgr.releaseFakePlayer(fakePlayer);

    gPlayerMgr.playerLogin(player);
    gMainThread.resetEnter(pid);

    std::unique_ptr<ResEnterGame> rsp(std::make_unique<ResEnterGame>());
    rsp->set_code(0);
    gMainThread.sendMessage2GateClient(sessionId, csessionId, "ResEnterGame", std::move(rsp));
    logInfo("reqEnterGameDbReturn err %llu", player->getCsessionId());
}


void reqBagData(uint64_t sessionId, uint64_t csessionId, char *data, size_t len)
{
    Player *player = gPlayerMgr.getPlayer(csessionId);
    if (!player)
    {
        logInfo("reqBagData no player");
        return;
    }

    std::unique_ptr<ResBagData> rsp = player->packBagData();
    gMainThread.sendMessage2GateClient(sessionId, csessionId, "resBagData", std::move(rsp));
}


typedef void (*FunctionPtr)(uint64_t, uint64_t, char *, size_t);
void dispatchGateClientMessage(uint64_t sessionId, uint16_t messageId, uint64_t csessionId, char *data, size_t len)
{
    //logInfo("dispatchGateClientMessage %d", messageId);
    FunctionPtr func = gMainThread.getProtoFunc(messageId);
    if(func)
    {
        func(sessionId, csessionId, data, len);
    }
}

void dispatchDbServerMessage(uint8_t messageId, char *data, size_t len)
{
    //logInfo("dispatchDbServerMessage %d", messageId);
    switch (messageId)
    {
    case g2dResDbLoginAuth:
        reqLoginAuthDbReturn(data, len);
        break;
    case g2dResDbSelectPlayer:
        reqSelectPlayerDbReturn(data, len);
        break;
    case g2dResDbCreatePlayer:
        reqCreatePlayerDbReturn(data, len);
        break;
    case g2dResDbEnterGame:
        reqEnterGameDbReturn(data, len);
        break;
    case g2dResReturnPlayerBagData:
        resReturnPlayerBagData(data, len);
        break;
    case g2dResReturnPlayerBaseData:
        resReturnPlayerBaseData(data, len);
        break;
    case g2dResReturnPlayerModuleData:
        resReturnPlayerModuleData(data, len);
        break;
    default:
        break;
    }
}
