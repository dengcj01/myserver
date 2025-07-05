
#pragma once

#include <unordered_map>
#include <vector>
#include <time.h>
#include <stdio.h>
#include "../../../common/Tools.hpp"
#include "../../../common/Json.hpp"
#include "../../../common/Timer.hpp"

#include "../../../common/net/Data.h"
#include <memory>
#include <algorithm>
#include <malloc.h>

#include "../../../../libs/mysql/mysql_connection.h"
#include "../../../../libs/mysql/mysql_error.h"
#include "../../../../libs/mysql/cppconn/resultset.h"
#include "../../../../libs/mysql/cppconn/statement.h"
#include "../../../../libs/mysql/cppconn/prepared_statement.h"
//#include "../../../../libs/jemalloc/jemalloc.h"

#include "../../../common/MysqlClient.h"
#include "../../../common/ParseConfig.hpp"
#include "../../../common/LoadPlayerData.hpp"
#include "../../../common/ProtoIdDef.h"
#include "../MainThread.h"



class RankItem
{
public:
    RankItem(uint64_t id, uint64_t v1, uint64_t v2 = 0, uint64_t v3 = 0)
        : id_(id),
          v1_(v1),
          v2_(v2),
          v3_(v3),
          time_(gTools.getMillisTime())

    {
    }

    bool operator <(const RankItem& r)
    {
        if (v1_ == r.v1_)
        {
            if (v2_ == r.v2_)
            {
                if (v3_ == r.v3_)
                {
                    return time_ > r.time_ ? true : false;
                }
                return v3_ < r.v3_;
            }
            return v2_ < r.v2_;
        }
        return v1_ < r.v1_;        
    }

    bool operator >(const RankItem& r)
    {
        if (v1_ == r.v1_)
        {
            if (v2_ == r.v2_)
            {
                if (v3_ == r.v3_)
                {
                    return time_ < r.time_ ? true : false;
                }
                return v3_ > r.v3_;
            }
            return v2_ > r.v2_;
        }
        return v1_ > r.v1_;        
    }

    bool isSame(uint64_t v1, uint64_t v2, uint64_t v3)
    {
        return v1_ == v1 && v2_ == v2 && v3_ == v3;
    }

    bool isEnlarge(uint64_t v1, uint64_t v2, uint64_t v3)
    {
        if(v1 > v1_ || (v1 == v1_ && v2 > v2_) || (v1 == v1_ && v2 == v2_ && v3 > v3_))
        {
            return true;
        }
        return false;   
    }



    uint64_t getId() { return id_; }
    uint64_t getVal1() { return v1_; }
    uint64_t getVal2() { return v2_; }
    uint64_t getVal3() { return v3_; }
    uint64_t getTime() {return time_;}

    uint64_t id_;
    uint64_t v1_;
    uint64_t v2_;
    uint64_t v3_;
    uint64_t time_ = 0;
};


class Rank
{
public:
    Rank(uint32_t rankLen, const std::string &name) : rankLen_(rankLen), name_(name)
    {
        data_.reserve(rankLen_);
    }

    void freeMem()
    {
        for (auto it = data_.begin(); it != data_.end(); ++it)
        {
            delete *it;
            *it = nullptr;
        }
    }

    // 第一个小于目标值索引
    int binarySearchEnlarge(const RankItem& target)
    {
        int left = 0;
        int right = data_.size() - 1;
        int idx = -1;
        while(left <= right)
        {
            int mid = left + ((right - left) >> 1);
            if(*(data_[mid]) < target)
            {
                idx = mid;
                right = mid - 1; // 继续往左边找小于的
            }
            else
            {
                left = mid + 1;
            }
        }

        return idx;
    }    

    // 最后一个大于新值的索引
    int binarySearchShrink(const RankItem& target)
    {
        int left = 0;
        int right = data_.size() - 1;
        int result = -1;



        while (left <= right)
        {
            int mid = left + ((right - left) >> 1);
            
            if(*(data_[mid]) > target)
            {

                result = mid;
                left = mid + 1;
            } 
            else 
            {
                right = mid - 1;
            }
        }
        
        return result;
    }   


    void updateRank(uint64_t id, uint64_t v1, uint64_t v2 = 0, uint64_t v3 = 0)
    {
        size_t dataLen = data_.size();
        if(dataLen == 0)
        {
            data_.emplace_back(new RankItem(id, v1, v2, v3));
        }
        else
        {
            int ranking = getRanking(id);
            RankItem *item = getRankItem(ranking);

            if(ranking > 0 && !item)
            {
                logInfo("updateRank err %llu", id);
                return;
            }

            if(item && item->isSame(v1, v2, v3))
            {
                return;
            }

            bool enlarge = true;
            if(item && !item->isEnlarge(v1, v2, v3))
            {
                enlarge = false;
            }

            //logInfo("xxxxxxxxxxxxxxxxxxxxx %d %d",enlarge, ranking);

            if(enlarge) // 新值变大
            {
                RankItem r(id, v1, v2, v3);
                // if(item)
                // {
                //     r.time_ = item->time_;
                // }

                int idx = binarySearchEnlarge(r); // 第一个小于新值的索引

                //logInfo("xxxxxxxxxxxxxxxxxxxxx11 %d",idx);

                if(idx == -1)
                {
                    if(!item && dataLen < rankLen_)
                    {
                        data_.emplace_back(new RankItem(id, v1, v2, v3));
                    }
                }
                else
                {
                    if(item && ranking - 1 == idx) // 找到了自己的位置33, 33, 33, 28,26, 20, 11, 10, 4, 2,1 原本是1新值是2或者是第一个,
                    {
                        item->v1_ = v1;
                        item->v2_ = v2;
                        item->v3_ = v3;
                    }       
                    else // 不是自己的位置
                    {
                        if(!item)
                        {
                            data_.insert(data_.begin() + idx, new RankItem(id, v1, v2, v3));

                            size_t curLen = data_.size();
                            if(curLen > rankLen_)
                            {
                                RankItem *item = data_[curLen - 1];
                                delete item;
                                item = nullptr;
                                data_.pop_back();
                            }
                        }
                        else
                        {
                            // 10, 9, 8, 7, 6, 5, 4, 3, 2 原来是4, 新值是8 5覆盖4, 6覆盖5
                            // 10, 9, 8, 8, 7, 6, 5, 3, 2 覆盖后
                            for(int i = ranking - 1; i > idx; i--) // 往后覆盖
                            {
                                RankItem* pre = data_[i - 1];
                                RankItem* now = data_[i];

                                now->v1_ = pre->v1_;
                                now->v2_ = pre->v2_;
                                now->v3_ = pre->v3_;
                                now->time_ = pre->time_;
                                now->id_ = pre->id_;
                            }

                            RankItem* now = data_[idx];
                            now->v1_ = v1;
                            now->v2_ = v2;
                            now->v3_ = v3;
                            now->id_ = id;
                        }                         
                    }                                
                }
            }
            else
            {
                RankItem r(id, v1, v2, v3);
                //r.time_ = item->time_;

                int idx = binarySearchShrink(r); // 最后一个大于新值的索引

                //logInfo("xxxxxxxxxxxxxxxxxxxxx222 %d",idx);

                if(idx != -1)
                {
                    //10, 9, 9, 9, 8, 8, 8, 7 ,6, 5, 5, 5, 4, 3, 3, 3, 2, 2 原来是顺数第一个数字9,新值是8
                    //10, 9, 9, 8, 8, 8, 8, 7 ,6, 5, 5, 5, 4, 3, 3, 3, 2, 2 覆盖后
                    for(int i = ranking - 1; i < idx; i++) // 往前覆盖
                    {
                        RankItem* last = data_[i + 1];
                        RankItem* now = data_[i];

                        now->v1_ = last->v1_;
                        now->v2_ = last->v2_;
                        now->v3_ = last->v3_;
                        now->time_ = last->time_;
                        now->id_ = last->id_;                        
                    }

                    RankItem* now = data_[idx];
                    now->v1_ = v1;
                    now->v2_ = v2;
                    now->v3_ = v3;
                    now->id_ = id;  


                }
            }
        }

        mapRank();
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
        if (ranking > lens || ranking == 0)
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
            //itemJson["serverid"] = item->serverId_;
            itemJson["v2"] = item->v2_;
            itemJson["v3"] = item->v3_;
            itemJson["time"] = item->time_;
            js.emplace_back(std::move(itemJson));
        }

        return true;
    }

    void deleteDbRank(uint8_t useDb = 0)
    {
        if(useDb == 1)
        {
            __delRankData(name_, gParseConfig.serverId_);
        }
        else
        {
            ReqDelRankData req;
            req.set_name(name_);
            req.set_serverid(gParseConfig.serverId_);

            gMainThread.sendMessage2DbServer(req, (uint16_t)ProtoIdDef::ReqDelRankData);
        }

    }

    void save(uint8_t useBd = 0)
    {
        nlohmann::json js;
        bool ok = false;

        for (auto &e : data_)
        {
            nlohmann::json itemJson;
            RankItem *item = e;
            itemJson["id"] = item->id_;
            itemJson["v1"] = item->v1_;
            itemJson["v2"] = item->v2_;
            itemJson["v3"] = item->v3_;
            itemJson["time"] = item->time_;
            js.emplace_back(itemJson);
            ok = true;
        }

        if(ok)
        {

            std::string data = js.dump();

            if(useBd == 1)
            {
                __saveRankData(name_, data, rankLen_, gParseConfig.serverId_);
            }
            else
            {
                ReqSaveRankData req;
                req.set_serverid(gParseConfig.serverId_);
                req.set_ranklen(rankLen_);
                req.set_name(name_);
                req.set_data(js.dump());
                gMainThread.sendMessage2DbServer(req, (uint16_t)ProtoIdDef::ReqSaveRankData);
            }
        }

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
        mapRank();
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

    void mapRank()
    {
        id2Idx_.clear();
        int i = 1;
        for (auto &e : data_)
        {
            id2Idx_.emplace(e->id_, i++);
        }  
    }

public:
    bool flag_ = false;
    uint32_t rankLen_;
    std::string name_;
    std::vector<RankItem *> data_;
    std::unordered_map<uint64_t, uint32_t> id2Idx_;
};

class RankMgr : public Singleton<RankMgr>
{
public:
    Rank *getRank(const char *name, uint32_t rankLen)
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

    void delRank(const char *name, uint8_t useDb = 0)
    {
        auto it = ranks_.find(name);
        if (it == ranks_.end())
        {
            return;
        }

        Rank *r = it->second;
        r->deleteDbRank(useDb);

        r->freeMem();
        r->id2Idx_.clear();

        delete r;

        ranks_.erase(it);
    }


    bool loadRankData()
    {
        ranks_.clear();
        int serverId = gParseConfig.serverId_;
        try
        {
            
            std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(gMysqlClient.getMysqlCon()->prepareStatement("select name,data,ranklen from rank where serverid=?"));
            if (!ps)
            {
                logInfo("loadRankData ps err");
                return false;
            }

            ps->setInt(1, serverId);
            std::unique_ptr<sql::ResultSet> rst = std::unique_ptr<sql::ResultSet>(ps->executeQuery());
            if (!rst)
            {
                logInfo("loadRankData rst err");
                return false;
            }

            while (rst->next())
            {
                const char *name = rst->getString("name").c_str();
                Rank *rank = getRank(name, rst->getInt("ranklen"));
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
                        uint64_t curTime = itemJson["time"];

                        RankItem *item = new RankItem(id, v1, v2, v3);
                        item->time_ = curTime;
                        rank->data_.emplace_back(item);
                    }
                    rank->mapRank();
                }
            }
        }
        catch (sql::SQLException &e)
        {
            logInfo(e.what());
            return false;
        }

        return true;
    }

    void saveRankData(uint8_t useDb = 0)
    {
        for (auto &e : ranks_)
        {
            e.second->save(useDb);
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
            Args *args = (Args *)malloc(sizeof(Args));
            args->obj_ = this;
            memset(args->rankName_, 0, 50);
            strncpy(args->rankName_, rank->name_.c_str(), rank->name_.size());

            gTimer.add(gTools.randoms(30, 60), &RankMgr::saveTime, args);
            dirty_[rank->name_] = true;
            rank->flag_ = true;
        }
    }

public:
    std::unordered_map<std::string, bool> dirty_;
    std::unordered_map<std::string, Rank *> ranks_;
};

#define gRankMgr RankMgr::instance()