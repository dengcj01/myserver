

#include "Player.h"
#include <map>
#include <unistd.h>
#include "../MainThread.h"
#include "../script/Script.h"
#include "../../../common/pb/Player.pb.h"
#include "../../../common/ProtoIdDef.h"
#include "../../../common/ParseConfig.hpp"
#include "../../../common/LoadPlayerData.hpp"
#include "../../../common/Tools.hpp"

Player::Player()
{

}

Player::~Player()
{


}

void Player::initBaseData(const PlayerBaseData &res)
{
    name_ = res.name();
    icon_ = res.icon();
    account_ = res.account();
    pf_ = res.pf();
    createTime_ = res.createtime();
    power_ = res.power();
    level_ = res.level();
    if(level_ <= 0)
    {
        level_ = 1;
    }
    vip_ = res.vip();
    exp_ = res.exp();
    guildId_ = res.guildid();
    chargeVal_ = res.chargeval();
    loginTime_ = res.logintime();
    headIcon_ = res.headicon();
    title_ = res.title();
    skin_ = res.skin();
    extra_ = res.extra();
    fromServerId_ = res.fromserverid();
    logoutTime_ = res.logouttime();
    firstLoginTime_ = res.firstlogintime();
    banTime_ = res.bantime();
    banReason_ = res.banreason();
    sex_ = res.sex();
    gmlv_ = res.gmlv();
    if(gmlv_ == 0)
    {
        gmlv_ = gParseConfig.gmlv_;
    }
}

void Player::initModuleData(uint8_t moduleId, const std::string &data)
{
    LuaBind::CallLua cl1(gScript.l, "gLoadPlayerModuleData");
    cl1.call<void, void>(pid_, moduleId, data);
}

void Player::saveBaseData(uint8_t useDb)
{
    ReqSavePlayerBaseData rp;
    rp.set_opt(0);
    rp.set_pid(pid_);


    PlayerBaseData *pd = rp.mutable_data();

    pd->set_pid(pid_);
    pd->set_name(name_);
    pd->set_icon(icon_);
    pd->set_power(power_);
    pd->set_level(level_);
    pd->set_vip(vip_);
    pd->set_exp(exp_);
    pd->set_guildid(guildId_);
    pd->set_chargeval(chargeVal_);
    pd->set_headicon(headIcon_);
    pd->set_title(title_);
    pd->set_skin(skin_);
    pd->set_extra(extra_);
    pd->set_exp(exp_);
    pd->set_logintime(loginTime_);
    pd->set_bantime(banTime_);
    pd->set_banreason(banReason_);
    pd->set_fromserverid(fromServerId_);
    pd->set_serverid(gParseConfig.serverId_);
    pd->set_gmlv(gmlv_);

    if(useDb == 1)
    {
        __saveBaseData(*pd, pid_, 0);
    }
    else
    {
        gMainThread.sendMessage2DbServer(rp, (uint16_t)ProtoIdDef::ReqSavePlayerBaseData);

    }

    

}


void Player::saveData(uint8_t useDb)
{
    saveBaseData(useDb);
    LuaBind::CallLua cl(gScript.l, "gGetPlayerModuleData", 1);
    std::map<uint8_t, std::string> datas = cl.call<std::map<uint8_t, std::string>, void>(pid_);
    saveModuleData(pid_, datas, useDb);

}

void Player::saveModuleData(uint64_t pid, const std::map<uint8_t, std::string> datas, uint8_t useDb)
{
    uint16_t serverId = gParseConfig.serverId_;
    for (auto &e : datas)
    {
        if(useDb == 1)
        {
            __saveModuleData(pid, e.first, e.second, serverId);
        }
        else
        {
            ReqSavePlayerModuleData rd;
            rd.set_pid(pid);
            rd.set_moduleid(e.first);
            rd.set_data(e.second);
            rd.set_serverid(serverId);
            gMainThread.sendMessage2DbServer(rd, (uint16_t)ProtoIdDef::ReqSavePlayerModuleData);
        }
    }    

}


void Player::setLevel(uint32_t lv)
{
    if (lv <= 0 )
    {
        return;
    }

    uint32_t oldLv = level_;
    level_  = lv;
    save();

    LuaBind::CallLua cl(gScript.l, "gPlayerLevelChange");
    cl.call<void, void>(this, pid_, oldLv, lv);
}


void Player::save()
{
    uint32_t val = gTools.randoms(120, 300);
    if (saveTime_ == 0)
    {
        saveTime_ = gTools.getNowTime() + val;
    }
}

void Player::notifyPlayerBaseData(uint64_t sessionId, uint64_t csessionId)
{
    std::unique_ptr<NotifyPlayerBaseData> res(std::make_unique<NotifyPlayerBaseData>());
    PlayerBaseData* pd = res.get()->mutable_data();
    
    pd->set_pid(pid_);
    pd->set_name(name_);
    pd->set_icon(icon_);
    pd->set_account(account_);
    pd->set_pf(pf_);
    pd->set_createtime(createTime_);
    pd->set_power(power_);
    pd->set_level(level_);
    pd->set_vip(vip_);
    pd->set_logintime(loginTime_);
    pd->set_guildid(guildId_);
    pd->set_chargeval(chargeVal_);
    pd->set_title(title_);
    pd->set_headicon(headIcon_);
    pd->set_skin(skin_);
    pd->set_serverid(gParseConfig.getServerId());
    pd->set_gmlv(gmlv_);
    pd->set_sex(sex_);
    pd->set_logouttime(logoutTime_);

    gMainThread.sendMessage2GateClient(sessionId, csessionId, "NotifyPlayerBaseData", std::move(res));

    
}


