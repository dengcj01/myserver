

#include "Bag.h"

#include <algorithm>

#include "../configparse/CfgMgr.h"
#include "../../../common/log/Log.h"
#include "../../../common/Tools.hpp"
#include "../../../common/ParseConfig.hpp"
#include "../../../common/LoadPlayerData.hpp"

#include "../pb/Bag.pb.h"
#include "../MainThread.h"
#include "../player/Player.h"
#include "../script/Script.h"

// 货币最大id
#define currencyMaxId 1000

// 物品操作定义
#define itemOptDefineAdd 1 // 添加
#define itemOptDefineDel 2 // 删除

Bag::Bag()
{
}

Bag::~Bag()
{
}

void Bag::saveData(uint64_t pid, bool db)
{
    ReqSavePlayerBagData req;
    req.set_pid(pid);

    for (auto &e : itemList_)
    {
        auto data = req.add_data();
        packData(data, e.second);
    }

    if (db)
    {
        gMainThread.sendMessage2DbServer(req, g2dReqSavePlayerBagData);
    }
    else
    {
        __saverBagData(req);
    }
}

void Bag::initBagData(ResReturnPlayerBagData &res)
{
    time_t curTime = time(0);
    for (int i = 0; i < res.data_size(); i++)
    {
        auto &data = res.data(i);
        uint32_t itemId = data.itemid();
        ItemCfg *cfg = gCfgMgr.getItemCfg(itemId);
        if (cfg)
        {
            time_t exTime = data.time();
            if (exTime > 0 && curTime >= exTime)
            {
                continue;
            }

            uint64_t guid = data.guid();
            Item item;

            item.guid_ = guid;
            item.owner_ = data.owner();
            item.id_ = itemId;
            item.cnt_ = data.count();
            item.level_ = data.level();
            item.star_ = data.star();
            item.exp_ = data.exp();
            item.expireTime_ = exTime;
            item.step_ = data.step();



            itemList_.emplace(guid, std::move(item));

            auto it = id2Item_.find(itemId);
            if (it == id2Item_.end())
            {
                id2Item_.emplace(itemId, std::list<Item *>{&itemList_[guid]});
            }
            else
            {
                it->second.emplace_back(&itemList_[guid]);
            }
        }
        else
        {
            logInfo("initBagData no existx itemId pid:%llu id:%d", res.pid(), itemId);
        }
    }
}

std::unique_ptr<ResBagData> Bag::packBagData()
{
    std::unique_ptr<ResBagData> res(std::make_unique<ResBagData>());
    for (auto &e : itemList_)
    {
        auto data = res->add_data();
        packData(data, e.second);
    }
    return res;
}


bool Bag::addItem(std::vector<Item> &news, std::vector<LogItem> &logs, std::vector<UpdateItem> &ui, uint32_t itemId, uint64_t cnt)
{
    ItemCfg *cfg = gCfgMgr.getItemCfg(itemId);
    if (!cfg || cnt <= 0)
    {
        logInfo("addItem err pid:%llu id:%d cnt:%llu", player_->pid_, itemId, cnt);
        return false;
    }

    auto it = id2Item_.find(itemId);
    if (it == id2Item_.end())
    {
        if (cfg->stack_ || itemId <= currencyMaxId)
        {
            Item im;
            im.id_ = itemId;
            im.cnt_ = cnt;
            uint64_t guid = gTools.createUniqueId();
            im.guid_ = guid;
            itemList_.emplace(guid, std::move(im));

            Item *ims = &itemList_[guid];
            id2Item_.emplace(itemId, std::list<Item *>{ims});

            news.emplace_back(Item(itemId,cnt));
            logs.emplace_back(LogItem(itemId, cnt, 0));
        }
        else
        {
            bool ok = false;
            for (uint64_t i = 1; i <= cnt; i++)
            {
                Item im;
                im.id_ = itemId;
                im.cnt_ = 1;
                uint64_t guid = gTools.createUniqueId();
                im.guid_ = guid;

                itemList_.emplace(guid, std::move(im));

                Item *ims = &itemList_[guid];
                if(ok == false)
                {
                    id2Item_.emplace(itemId, std::list<Item *>{ims});
                    ok = true;
                }
                else
                {
                    auto &itemList = id2Item_[itemId];
                    itemList.emplace_back(ims);
                }

            }

            news.emplace_back(Item(itemId, cnt));
            logs.emplace_back(LogItem(itemId, cnt, 0));
        }
    }
    else
    {
        auto& itemList = it->second;
        if (cfg->stack_ || itemId <= currencyMaxId)
        {
            auto itt = itemList.begin();
            Item *item = *itt;
            uint64_t oldCnt = item->cnt_;

            uint64_t maxVal = std::numeric_limits<uint64_t>::max();
            uint64_t addCnt = maxVal - oldCnt;

            if (cnt > addCnt)
            {
                cnt = addCnt;
            }
            item->cnt_ += cnt;

            ui.emplace_back(UpdateItem(item->guid_, item->cnt_));
            logs.emplace_back(LogItem(itemId, item->cnt_, oldCnt));
        }
        else
        {
            uint64_t oldCnt = itemList.size();
            for (uint64_t i = 1; i <= cnt; i++)
            {
                Item im;
                im.id_ = itemId;
                im.cnt_ = 1;
                uint64_t guid = gTools.createUniqueId();
                im.guid_ = guid;

                itemList_.emplace(guid, std::move(im));

                Item *ims = &itemList_[guid];
                itemList.emplace_back(ims);


            }

            news.emplace_back(Item(itemId, cnt));
            logs.emplace_back(LogItem(itemId, cnt, oldCnt));
        }
    }

    return true;
}

std::map<uint32_t, uint64_t> Bag::addItems(std::map<uint32_t, uint64_t> add, const char *desc, const char *extra)
{
    std::vector<Item> news;
    std::vector<LogItem> logs;
    std::vector<UpdateItem> ui;
    std::map<uint32_t, uint64_t> res;
    for (auto &e : add)
    {
        uint64_t &count = e.second;
        bool ret = addItem(news, logs, ui, e.first, count);
        if (ret)
        {
            res.emplace(e.first, count);
        }
    }

    notifyServerAddItem(news);
    notifyItemUpdate(ui);
    writeItemLog(logs, desc, extra);
    if(player_)
    {
        player_->save();
    }
    return res;
}

void Bag::costItem(std::vector<uint64_t> &del, std::vector<LogItem> &logs, std::vector<UpdateItem> &ui, uint32_t itemId, uint64_t cnt)
{
    ItemCfg *cfg = gCfgMgr.getItemCfg(itemId);
    if (!cfg || cnt <= 0)
    {
        logInfo("costItem err pid:%llu id:%d cnt:%llu", player_->pid_, itemId, cnt);
        return;
    }

    auto it = id2Item_.find(itemId);
    if (it == id2Item_.end())
    {
        return;
    }

    std::list<Item *> &itemList = it->second;
    if (cfg->stack_ || itemId <= currencyMaxId)
    {
        auto itt = itemList.begin();
        Item *item = *itt;
        uint64_t oldCnt = item->cnt_;

        cnt = cnt > oldCnt ? oldCnt : cnt;

        item->cnt_ -= cnt;

        uint64_t guid = item->guid_;
        if (item->cnt_ <= 0)
        {
            del.emplace_back(item->guid_);
            logs.emplace_back(LogItem(item->id_, 0, oldCnt));

            itemList.clear();
            id2Item_.erase(it);
            itemList_.erase(guid);
        }
        else
        {
            ui.emplace_back(UpdateItem(guid, item->cnt_));
            logs.emplace_back(LogItem(item->id_, cnt, oldCnt));
        }
    }
    else
    {
        uint64_t count = 0;
        uint64_t oldCnt = itemList.size();
        for (auto itt = itemList.begin(); itt != itemList.end();)
        {
            if (count++ >= cnt)
            {
                break;
            }

            Item *im = *itt;
            del.emplace_back(im->guid_);

            uint64_t guid = im->guid_;
            itemList.erase(itt++);
            itemList_.erase(guid);
        }

        logs.emplace_back(LogItem(itemId, cnt, oldCnt));
        if (itemList.empty())
        {
            id2Item_.erase(itemId);
        }
    }
}

void Bag::costItems(std::map<uint32_t, uint64_t> cost, const char *desc, const char *extra)
{
    std::vector<uint64_t> del;
    std::vector<LogItem> logs;
    std::vector<UpdateItem> ui;

    for (auto &e : cost)
    {
        costItem(del, logs, ui, e.first, e.second);
    }

    notifyServerDelItem(del);
    notifyItemUpdate(ui);
    writeItemLog(logs, desc, extra);
}

uint64_t Bag::getItemCountById(uint32_t itemId)
{
    ItemCfg *cfg = gCfgMgr.getItemCfg(itemId);
    if (!cfg)
    {
        return 0;
    }

    auto it = id2Item_.find(itemId);
    if (it == id2Item_.end())
    {
        return 0;
    }

    auto &itemList = it->second;
    if (cfg->stack_)
    {
        auto itt = itemList.begin();
        return (*itt)->cnt_;
    }

    return itemList.size();
}

uint64_t Bag::getItemCountByGuid(uint64_t guid)
{
    auto it = itemList_.find(guid);
    if (it != itemList_.end())
    {
        return it->second.cnt_;
    }
    return 0;
}

void Bag::removeItemById(uint32_t itemId, const char *desc, const char *extra)
{
    auto it = id2Item_.find(itemId);
    if(it == id2Item_.end())
    {
        return;
    }


    std::vector<uint64_t> del;
    std::vector<LogItem> logs;
    uint64_t oldCnt = 0;

    for (auto &e : it->second)
    {
        uint64_t guid = e->guid_;

        del.emplace_back(guid);
        oldCnt += e->cnt_;
        itemList_.erase(guid);
    }
    it->second.clear();
    id2Item_.erase(it);

    logs.emplace_back(LogItem(itemId, oldCnt, oldCnt));
    notifyServerDelItem(del);
    writeItemLog(logs, desc, extra);
}

void Bag::removeItemByGuid(uint64_t guid, const char *desc, const char *extra)
{
    auto it = itemList_.find(guid);
    if (it == itemList_.end())
    {
        return;
    }

    std::vector<uint64_t> del;
    std::vector<LogItem> logs;

    del.emplace_back(guid);

    Item *item = &it->second;
    uint32_t itemId = item->id_;

    auto it1 = id2Item_.find(itemId);
    if (it1 != id2Item_.end())
    {
        auto& itemList = it1->second;

        for (auto it2 = itemList.begin(); it2 != itemList.end(); it2++)
        {
            if ((*it2)->guid_ == guid)
            {
                itemList.erase(it2);
                logs.emplace_back(LogItem(itemId, item->cnt_, item->cnt_));
                break;
            }
        }

        itemList_.erase(it);

        if (itemList.empty())
        {
            id2Item_.erase(itemId);
        }
    }

    notifyServerDelItem(del);

    writeItemLog(logs, desc, extra);
}

bool Bag::itemEnough(std::map<uint32_t, uint64_t> items)
{
    for (auto e : items)
    {
        uint64_t count = getItemCountById(e.first);
        if (count < e.second)
        {
            return false;
        }
    }

    return true;
}

void Bag::writeItemLog(std::vector<LogItem> &logs, const char *desc, const char *extra)
{
    if (strlen(desc) > 0 && !logs.empty())
    {
        WriteLogData wd;
        if (player_)
        {
            wd.set_pid(player_->getPid());
            wd.set_account(player_->getAccount());
            wd.set_pf(player_->getPf());
            wd.set_desc(desc);
            wd.set_serverid(gParseConfig.serverId_);
            wd.set_extra(extra);
            wd.set_name(player_->getName());
        }

        for (auto &e : logs)
        {
            auto data = wd.add_data();
            data->set_id(e.id_);
            data->set_cnt(e.cnt_);
            data->set_oldcnt(e.oldCnt_);
        }

        gMainThread.sendMessage2LogServer(wd, 1);
    }
}

void Bag::notifyServerDelItem(const std::vector<uint64_t> &del)
{
    if (del.empty())
    {
        return;
    }

    std::unique_ptr<ResServerOptItem> res(std::make_unique<ResServerOptItem>());
    res->set_opt(itemOptDefineDel);

    ItemData *data = res->add_data();
    for (auto &e : del)
    {
        data->set_guid(e);
    }

    gMainThread.sendMessage2GateClient(player_->sessionId_, player_->csessionId_, "ResServerOptItem", std::move(res));
}

void Bag::notifyServerAddItem(const std::vector<Item> &add)
{
    if (add.empty())
    {
        return;
    }

    std::unique_ptr<ResServerOptItem> res(std::make_unique<ResServerOptItem>());
    res->set_opt(itemOptDefineAdd);

    ItemData *data = res->add_data();
    for (auto &e : add)
    {
        packData(data, e);
    }

    gMainThread.sendMessage2GateClient(player_->sessionId_, player_->csessionId_, "ResServerOptItem", std::move(res));
}

void Bag::notifyItemUpdate(std::vector<UpdateItem> &ui)
{
    if (ui.empty())
    {
        return;
    }

    std::unique_ptr<ResBagItemCntUpdate> res(std::make_unique<ResBagItemCntUpdate>());

    ItemData *data = res->add_data();
    for (auto &e : ui)
    {
        data->set_guid(e.guid_);
        data->set_count(e.cnt_);
    }

    gMainThread.sendMessage2GateClient(player_->sessionId_, player_->csessionId_, "ResBagItemCntUpdate", std::move(res));
}
