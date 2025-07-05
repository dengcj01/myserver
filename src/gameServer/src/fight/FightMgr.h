// #pragma once

// #include "../../../common/Singleton.h"
// #include "../../../common/net/Data.h"

// #include <vector>
// #include <thread>
// #include <queue>
// #include <thread>
// #include <mutex>
// #include <condition_variable>
// #include <atomic>
// #include <map>

// class FightData
// {
// public:
//     uint64_t uid_;
//     const char *team_;
// };

// class FightMgr : public Singleton<FightMgr>
// {
// public:
//     ~FightMgr();
//     void init();
//     void randomFunc();
//     void seqFunc();
//     std::string checkAndPack(uint8_t fightType, uint32_t groupId);
//     void addRandom(uint64_t uid, const char *team);
//     void addSeq(uint64_t uid, const char *team);
    

//     std::atomic<bool> quit_{false};
//     std::atomic<bool> quit1_{false};
//     std::mutex mutex_;
//     std::condition_variable cond_;
//     std::queue<FightData> queue_;
//     std::vector<std::thread> threadPool_;

//     std::mutex mutex1_;
//     std::condition_variable cond1_;
//     std::queue<FightData> queue1_;
//     std::thread seqThread_;

// };

// #define gFightMgr FightMgr::instance()