
#pragma once

#include <unordered_map>
#include <vector>
#include <time.h>
#include <stdio.h>
#include "Tools.hpp"
#include "Json.hpp"
#include "Timer.hpp"

#include "net/Data.h"

#include <algorithm>
#include <malloc.h>

#include "../../libs/mysql/mysql_connection.h"
#include "../../libs/mysql/mysql_error.h"
#include "../../libs/mysql/cppconn/resultset.h"
#include "../../libs/mysql/cppconn/statement.h"
#include "../../libs/mysql/cppconn/prepared_statement.h"
#include "../../libs/jemalloc/jemalloc.h"
#include "MysqlClient.h"
#include "ParseConfig.hpp"
#include "Tools.hpp"

#define rankDataSvaeTime 300

class RankItem
{
public:
    RankItem(uint64_t id, uint64_t v1, uint32_t serverId, uint64_t v2 = 0, uint64_t v3 = 0)
        : id_(id),
          v1_(v1),
          serverId_(serverId),
          v2_(v2),
          v3_(v3),
          time_(gTools.getMillisTime())

    {
    }

    uint64_t getId() { return id_; }
    uint64_t getVal1() { return v1_; }
    uint64_t getVal2() { return v2_; }
    uint64_t getVal3() { return v3_; }
    uint64_t getServerId() { return serverId_; }

    uint64_t id_;
    uint64_t v1_;
    uint32_t serverId_;
    uint64_t v2_;
    uint64_t v3_;
    uint64_t time_ = 0;
};

static bool customCompare(const RankItem *obj1, const RankItem *obj2)
{
    if (obj1->v1_ == obj2->v1_)
    {
        if (obj1->v2_ == obj2->v2_)
        {
            if (obj1->v3_ == obj2->v3_)
            {
                return obj1->time_ < obj2->time_ ? true : false;
            }
            return obj1->v3_ > obj2->v3_;
        }
        return obj1->v2_ > obj2->v2_;
    }
    return obj1->v1_ > obj2->v1_;
}

class Rank
{
public:
    Rank(uint32_t rankLen, const std::string &name) : rankLen_(rankLen), name_(name)
    {
        data_.reserve(20);
    }

    void freeMem()
    {
        for (auto it = data_.begin(); it != data_.end(); ++it)
        {
            delete *it;
            *it = nullptr;
        }
    }

    void updateServerId(uint32_t serverId)
    {
        for (auto &e : data_)
        {
            e->serverId_ = serverId;
        }
    }

    void updateRank(uint64_t id, uint64_t v1, uint32_t serverId, uint64_t v2 = 0, uint64_t v3 = 0)
    {
        int ranking = getRanking(id);
        bool ok = false;

        if (ranking == 0)
        {
            size_t dataLen = data_.size();
            if (dataLen < rankLen_ || v1 > data_[dataLen - 1]->v1_)
            {
                if (dataLen >= rankLen_)
                {
                    RankItem *item = data_[dataLen - 1];
                    delete item;
                    item = nullptr;

                    data_.pop_back();
                }

                RankItem *item = new RankItem(id, v1, serverId, v2, v3);
                data_.emplace_back(item);
                ok = true;
            }
        }
        else
        {
            RankItem *item = getRankItem(ranking);
            if (!item)
            {
                logInfo("-------------- updateRank err %lu", id);
                return;
            }

            item->v1_ = v1;
            item->v2_ = v2;
            item->v3_ = v3;
            ok = true;
        }

        if (ok)
        {
            //sortRank();
        }
    }

    void sortRank()
    {
        id2Idx_.clear();
        std::sort(data_.begin(), data_.end(), customCompare);
        int i = 1;
        for (auto &e : data_)
        {
            id2Idx_.emplace(e->id_, i++);
        }
    }

    // 获取当前排名
    int getRanking(uint64_t id)
    {
        auto it = id2Idx_.find(id);
        if (it == id2Idx_.end())
        {
            return 0;
        }
        return it->second;
    }

    // 根据排名获取对应的排行项对象
    RankItem *getRankItem(int ranking)
    {
        int lens = data_.size();
        if (ranking > lens)
        {
            return 0;
        }

        return data_[ranking - 1];
    }

    std::vector<RankItem *> getRankItemList()
    {
        return data_;
    }

    bool serislzieData(nlohmann::json &js)
    {
        if (data_.size() == 0)
        {
            return false;
        }

        for (auto &e : data_)
        {
            nlohmann::json itemJson;
            RankItem *item = e;
            itemJson["id"] = item->id_;
            itemJson["v1"] = item->v1_;
            itemJson["serverid"] = item->serverId_;
            itemJson["v2"] = item->v2_;
            itemJson["v3"] = item->v3_;
            itemJson["time"] = item->time_;
            js.emplace_back(std::move(itemJson));
        }

        return true;
    }

    void deleteDbRank()
    {
        sql::PreparedStatement *ps = nullptr;
        try
        {
            ps = gMysqlClient.getMysqlCon()->prepareStatement("delete from rank where name=?");
            ps->setString(1, name_);
            ps->execute();
            delete ps;
        }
        catch (sql::SQLException &e)
        {
            logInfo(e.what());
        }
    }

    void save()
    {
        sql::PreparedStatement *ps = nullptr;
        try
        {
            nlohmann::json js;
            bool res = serislzieData(js);
            if (res)
            {
                ps = gMysqlClient.getMysqlCon()->prepareStatement("replace into rank(name,data,serverid,ranklen)values(?,?,?,?)");
                ps->setString(1, name_);
                ps->setString(2, js.dump());
                ps->setInt(3, gParseConfig.serverId_);
                ps->setInt(4, rankLen_);
                ps->execute();
                delete ps;
            }
            else
            {
                deleteDbRank();
            }
        }
        catch (sql::SQLException &e)
        {
            logInfo(e.what());
        }
    }

    const char *getData()
    {
        nlohmann::json js;
        bool ok = serislzieData(js);
        if (ok)
        {
            return js.dump().c_str();
        }
        return "";
    }

    void delRankItemByRanking(int ranking)
    {
        int lens = data_.size();
        if (ranking <= 0 || lens <= 0 || ranking > lens)
        {
            return;
        }

        int idx = ranking - 1;
        auto item = data_[idx];
        delete item;
        data_.erase(data_.begin() + idx);
        sortRank();
    }

    void delRankItemById(uint64_t id)
    {
        auto it = id2Idx_.find(id);
        if (it == id2Idx_.end())
        {
            return;
        }

        delRankItemByRanking(it->second);
    }

public:
    bool flag_ = false;
    uint32_t rankLen_ = 50;
    std::string name_;
    std::vector<RankItem *> data_;
    std::unordered_map<uint64_t, uint32_t> id2Idx_;
};

class RankMgr : public Singleton<RankMgr>
{
public:
    Rank *initRank(const char *name, uint32_t rankLen)
    {
        auto it = ranks_.find(name);
        if (it == ranks_.end())
        {
            Rank *rank = new Rank(rankLen, name);
            ranks_.emplace(name, rank);
            return rank;
        }

        return it->second;
    }
    Rank *getRank(const char *name)
    {
        auto it = ranks_.find(name);
        if (it == ranks_.end())
        {
            return 0;
        }
        return it->second;
    }

    void delRank(const char *name)
    {
        auto it = ranks_.find(name);
        if (it == ranks_.end())
        {
            return;
        }

        Rank *r = it->second;

        r->freeMem();

        r->deleteDbRank();

        {
            std::vector<RankItem *>().swap(r->data_);
            r->id2Idx_.clear();
        }

        delete r;
        r = nullptr;

        ranks_.erase(name);
    }

    void cleanRank(const char *name)
    {
        auto it = ranks_.find(name);
        if (it == ranks_.end())
        {
            return;
        }

        Rank *r = it->second;

        r->freeMem();

        r->deleteDbRank();

        {
            std::vector<RankItem *>().swap(r->data_);
            r->id2Idx_.clear();
        }
    }

    void loadRankData()
    {
        ranks_.clear();
        int serverId = gParseConfig.serverId_;
        sql::PreparedStatement *ps = nullptr;
        try
        {
            ps = gMysqlClient.getMysqlCon()->prepareStatement("select name,data,ranklen from rank where serverid=?");
            ps->setInt(1, serverId);

            sql::ResultSet *rst = ps->executeQuery();
            while (rst->next())
            {
                const char *name = rst->getString("name").c_str();
                Rank *rank = initRank(name, rst->getInt("ranklen"));
                if (rank)
                {
                    std::string data = rst->getString("data");
                    nlohmann::json js = nlohmann::json::parse(data);
                    for (const auto &itemJson : js)
                    {
                        uint64_t id = itemJson["id"];
                        uint64_t v1 = itemJson["v1"];
                        uint64_t v2 = itemJson["v2"];
                        uint64_t v3 = itemJson["v3"];
                        uint32_t serverId = itemJson["serverid"];
                        uint64_t curTime = itemJson["time"];

                        RankItem *item = new RankItem(id, v1, serverId, v2, v3);
                        item->time_ = curTime;
                        rank->data_.emplace_back(item);
                    }
                }
            }
            delete rst;
            // ps->getMoreResults();
            delete ps;
        }
        catch (sql::SQLException &e)
        {
            logInfo(e.what());
        }
    }

    void saveRankData()
    {
        for (auto &e : ranks_)
        {
            e.second->save();
        }
    }

    static void saveTime(Args *args)
    {
        RankMgr *m = (RankMgr *)args->obj_;
        auto it = m->dirty_.find(args->rankName_);
        if (it != m->dirty_.end())
        {
            auto rit = m->ranks_.find(args->rankName_);
            if (rit != m->ranks_.end())
            {
                Rank *r = rit->second;
                r->save();
                r->flag_ = false;
            }
            m->dirty_.erase(it);
        }
    }

    void save(Rank *rank, bool ref = false)
    {
        if (!rank)
        {
            return;
        }

        if (ref)
        {
            rank->save();
            return;
        }

        if (!rank->flag_)
        {
            Args *args = (Args *)je_malloc(sizeof(Args));
            args->obj_ = this;
            memset(args->rankName_, 0, 50);
            strncpy(args->rankName_, rank->name_.c_str(), rank->name_.size());

            gTimer.add(rankDataSvaeTime, &RankMgr::saveTime, args);
            dirty_[rank->name_] = true;
            rank->flag_ = true;
        }
    }

public:
    std::unordered_map<std::string, bool> dirty_;
    std::unordered_map<std::string, Rank *> ranks_;
};

#define gRankMgr RankMgr::instance()