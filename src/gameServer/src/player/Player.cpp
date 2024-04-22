

#include "Player.h"
#include <map>

#include "../MainThread.h"
#include "../script/Script.h"
#include "../pb/Bag.pb.h"
#include "../bag/Bag.h"

#include "../../../common/ParseConfig.hpp"
#include "../../../common/LoadPlayerData.hpp"
#include "../../../common/Tools.hpp"

Player::Player()
{
    fakeModuleIdList_.clear();
    bag_ = new Bag();
    bag_->player_ = this;
}

Player::~Player()
{
    if (bag_)
    {
        delete bag_;
        bag_ = nullptr;
    }

    fakeModuleIdList_.clear();
}

void Player::initBagData(ResReturnPlayerBagData &res)
{
    bag_->initBagData(res);
}

void Player::initBaseData(const PlayerBaseData &res)
{
    pid_ = res.pid();
    name_ = res.name();
    icon_ = res.icon();
    account_ = res.account();
    pf_ = res.pf();
    createTime_ = res.createtime();
    power_ = res.power();
    level_ = res.level();
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
}

void Player::initModuleData(uint8_t moduleId, const std::string &data)
{
    LuaBind::CallLua cl1(gScript.l, "gLoadPlayerModuleData");
    cl1.call<void, void>(pid_, moduleId, data);
}

void Player::saveBaseData(bool db)
{
    ReqSavePlayerBaseData rp;
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

    if (db)
    {
        gMainThread.sendMessage2DbServer(rp, g2dReqSavePlayerBaseData);
    }
    else
    {
        __saveBaseData(*pd, pid_);
    }
}

void Player::saveBagData(bool db)
{
    if (bag_)
    {
        bag_->saveData(pid_);
    }
}

void Player::saveData(bool db)
{
    saveBaseData(db);
    saveModuleData(pid_, 0, db);
    saveBagData(db);
}

void Player::saveModuleData(uint64_t pid, uint8_t mod, bool db)
{
    const char *name = "gGetPlayerModuleData";
    if (mod == 1)
    {
        name = "gTimerGetPlayerModuleData";
    }

    LuaBind::CallLua cl(gScript.l, name);
    std::map<uint8_t, const char *> datas = cl.call<std::map<uint8_t, const char *>, void>(pid, mod);
    uint16_t serverId = gParseConfig.serverId_;
    for (auto &e : datas)
    {
        if (db)
        {
            ReqSavePlayerModuleData rd;
            rd.set_pid(pid);
            rd.set_moduleid(e.first);
            rd.set_data(e.second);
            rd.set_serverid(serverId);
            gMainThread.sendMessage2DbServer(rd, g2dReqSavePlayerModuleData);
        }
        else
        {
            __saveModuleData(pid, e.first, e.second, serverId);
        }
    }
}

bool Player::itemEnough(std::map<uint32_t, uint64_t> items)
{
    return bag_->itemEnough(items);
}

void Player::costItems(std::map<uint32_t, uint64_t> cost, const char *logDesc, const char *extra)
{
    bag_->costItems(cost, logDesc, extra);
    save();
}

std::unique_ptr<ResBagData> Player::packBagData()
{
    if (bag_)
    {
        return bag_->packBagData();
    }

    return std::make_unique<ResBagData>();
}

std::map<uint32_t, uint64_t> Player::addItems(std::map<uint32_t, uint64_t> add, const char *logDesc, const char *extra)
{
    return bag_->addItems(add, logDesc, extra);
}

uint64_t Player::getItemCount(uint32_t itemId)
{
    return bag_->getItemCountById(itemId);
}

void Player::removeItemById(uint32_t itemId, const char *desc, const char *extra)
{
    bag_->removeItemById(itemId, desc, extra);
    save();
}

void Player::removeItemByGuid(uint64_t guid, const char *desc, const char *extra)
{
    bag_->removeItemByGuid(guid, desc, extra);
    save();
}

void Player::save()
{
    uint32_t val = gTools.random(180, 300);
    if (saveTime_ == 0)
    {
        saveTime_ = time(0) + val;
    }
}