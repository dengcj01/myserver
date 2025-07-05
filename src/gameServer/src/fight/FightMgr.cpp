

// #include "FightMgr.h"
// #include <sstream>
// #include <iostream>
// #include <unistd.h>
// #include "../../../common/log/Log.h"
// #include "../../../common/net/Data.h"
// #include "../../../common/Json.hpp"
// #include "Fight.h"
// #include "../MainThread.h"
// #include "../configparse/CfgMgr.h"


// FightMgr::~FightMgr()
// {
//     quit_.store(true, std::memory_order_relaxed);
//     quit1_.store(true, std::memory_order_relaxed);
//     sleep(1);
// }

// void FightMgr::randomFunc()
// {
//     while(true)
//     {
        
//         std::unique_lock<std::mutex> lk(mutex_);
//         while (queue_.empty())
//         {
//             cond_.wait(lk);
//         }

//         if (quit_.load(std::memory_order_relaxed))
//         {
//             logInfo("------------------------quit randomFunc------------");
//             break;
//         }

//         FightData fd = std::move(queue_.front());
//         queue_.pop();
//         lk.unlock();


//         Fight f;
//         f.start(fd.uid_, fd.team_);


//     }
// }

// void FightMgr::seqFunc()
// {
//     while (true)
//     {
//         std::unique_lock<std::mutex> lk(mutex1_);
//         while (queue1_.empty())
//         {
//             cond1_.wait(lk);
//         }

//         if (quit1_.load(std::memory_order_relaxed))
//         {
//             logInfo("------------------------quit seqFunc------------");
//             break;
//         }

//         FightData fd = std::move(queue1_.front());
//         queue1_.pop();
//         lk.unlock();

//         Fight f;
//         f.start(fd.uid_, fd.team_);
//     }
// }

// void FightMgr::init()
// {
//     for (uint8_t i = 0; i < 4; ++i)
//     {
//         threadPool_.emplace_back(std::thread(&FightMgr::randomFunc, this));
//     }
//     for (uint8_t i = 0; i < 4; ++i)
//     {
//         threadPool_[i].detach();
//     }
//     seqThread_ = std::thread(&FightMgr::seqFunc, this);
//     seqThread_.detach();
// }

// std::string FightMgr::checkAndPack(uint8_t fightType, uint32_t groupId)
// {
//     auto groupCfg = gCfgMgr.existGroup(groupId);
//     if (!groupCfg)
//     {
//         logInfo("FightMgr::checkAndPack err type:%d groupid:%d", fightType, groupId);
//         return "";
//     }

//     nlohmann::json js;
//     js["pid"] = groupId;

//     bool ch = false;
//     for (auto &e : groupCfg->monster_)
//     {
//         uint32_t mid = e.second;
//         auto cfg = gCfgMgr.existMonster(mid);
//         if (!cfg)
//         {
//             logInfo("FightMgr::checkAndPack err1 type:%d groupid:%d mid:%d", fightType, groupId, mid);
//             return "";
//         }

//         nlohmann::json et;
//         et["id"] = mid;
//         et["step"] = cfg->step_;
//         et["star"] = cfg->star_;
//         et["level"] = cfg->level_;
//         et["skin"] = cfg->skin_;
//         et["pos"] = e.first;

//         for(auto skillId :cfg->skills_)
//         {
//             et["skills"].emplace_back(skillId);
//         }

//         for(auto &e:cfg->attr_)
//         {
//             et["attr"][std::to_string(e.first)] = e.second;
//         }

//         js["enList"].emplace_back(std::move(et));
//         ch = true;
//     }

//     if(!ch)
//     {
//         logInfo("FightMgr::checkAndPack err2 type:%d groupid:%d", fightType, groupId);
//         return "";
//     }

//     return js.dump();
// }

// void FightMgr::addRandom(uint64_t uid, const char *team)
// {
//     FightData fd;
//     fd.team_ = team;
//     fd.uid_ = uid;

//     std::unique_lock<std::mutex> lk(mutex_);
//     queue_.emplace(std::move(fd));

//     lk.unlock();
//     cond_.notify_all();
// }

// void FightMgr::addSeq(uint64_t uid, const char *team)
// {
//     FightData fd;
//     fd.team_ = team;
//     fd.uid_ = uid;

//     std::unique_lock<std::mutex> lk(mutex1_);
//     queue1_.emplace(std::move(fd));

//     lk.unlock();
//     cond1_.notify_one();
// }