

#pragma once

#include <unordered_map>
#include <list>
#include "../../../common/pb/ServerCommon.pb.h"
#include "../pb/Bag.pb.h"


class Player;

struct Item
{
    Item()
    {

    }
    Item(uint32_t id, uint64_t cnt):
    id_(id),cnt_(cnt)
    {

    }
    uint32_t id_ = 0;
    uint64_t cnt_ = 0;
    uint32_t level_ = 0;
    uint32_t exp_ = 0;
    uint32_t star_ = 0;
    int expireTime_ = 0;
    uint64_t owner_ = 0;
    uint64_t guid_ = 0;
    uint32_t step_ = 0;
};

struct LogItem
{
    LogItem(uint32_t id, uint64_t cnt, uint64_t oldCnt) : id_(id),
                                                          cnt_(cnt),
                                                          oldCnt_(oldCnt)
    {
    }
    uint32_t id_;
    uint64_t cnt_;
    uint64_t oldCnt_;
};

struct UpdateItem
{
    UpdateItem(uint64_t guid, uint64_t cnt) : guid_(guid),
                                              cnt_(cnt)
    {
    }
    uint64_t guid_;
    uint64_t cnt_;
};

class Bag
{
public:
    Bag();
    ~Bag();

    void initBagData(ResReturnPlayerBagData &res);
    void saveData(uint64_t pid, bool db = true);
    bool addItem(std::vector<Item> &news, std::vector<LogItem> &logs, std::vector<UpdateItem> &ui, uint32_t itemId, uint64_t cnt);
    std::map<uint32_t, uint64_t> addItems(std::map<uint32_t, uint64_t> add, const char *desc = "", const char *extra = "");
    void costItem(std::vector<uint64_t> &del, std::vector<LogItem> &logs, std::vector<UpdateItem> &ui, uint32_t itemId, uint64_t cnt);
    void costItems(std::map<uint32_t, uint64_t> cost, const char *desc = "", const char *extra = "");
    uint64_t getItemCountById(uint32_t itemId);
    uint64_t getItemCountByGuid(uint64_t guid);
    void removeItemById(uint32_t itemId, const char *desc = "", const char *extra = "");
    void removeItemByGuid(uint64_t guid, const char *desc = "", const char *extra = "");
    bool itemEnough(std::map<uint32_t, uint64_t> items);
    void writeItemLog(std::vector<LogItem> &logs, const char *desc, const char *extra);
    void notifyServerDelItem(const std::vector<uint64_t> &del);
    void notifyServerAddItem(const std::vector<Item> &add);
    void notifyItemUpdate(std::vector<UpdateItem> &ui);
    std::unique_ptr<ResBagData> packBagData();

    template <typename T>
    void packData(T data, const Item &item)
    {
        data->set_guid(item.guid_);
        data->set_owner(item.owner_);
        data->set_itemid(item.id_);
        data->set_exp(item.exp_);
        data->set_level(item.level_);
        data->set_star(item.star_);
        data->set_count(item.cnt_);
        data->set_time(item.expireTime_);
        data->set_step(item.step_);
    }

public : 
    std::unordered_map<uint64_t, Item> itemList_;
    std::unordered_map<uint32_t, std::list<Item *>> id2Item_;
    Player *player_;
};