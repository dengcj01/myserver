




// #include "Fight.h"
// #include "../../../common/net/Data.h"
// #include "../../../common/CommDefine.h"
// #include "../../../common/log/Log.h"
// #include "../../../common/Tools.hpp"

// #include <mutex>
// #include <condition_variable>
// #include <atomic>
// #include <queue>
// #include <algorithm>

// #include "FightEntity.h"
// #include "FightSkill.h"

// extern std::queue<Task> gQueue;
// extern std::mutex gMutex;
// extern std::condition_variable gCondVar;

// static bool sortByAttrKeyValue(const FightEntity *a, const FightEntity *b)
// {
//     auto ita = a->attr_.find(AttrTypeDefine::AttrTypeDefine_speed);
//     auto itb = b->attr_.find(AttrTypeDefine::AttrTypeDefine_speed);
//     if (ita != a->attr_.end() && itb != b->attr_.end())
//     {
//         return ita->second > itb->second;
//     }

//     return false;
// }

// Fight::~Fight()
// {

// }

// void Fight::parse(std::vector<FightEntity *> &vec, nlohmann::json &team, uint8_t teamId)
// {
//     for(auto& e:team["enList"])
//     {
//         FightEntity *fe = new FightEntity();
//         fe->teamId_ = teamId;

//         for (auto sk : e["skills"])
//         {
//             uint16_t skillId = sk.get<uint16_t>();
//             FightSkill *fs = new FightSkill(skillId);
//             fs->fe_ = fe;
//             fe->skills_.emplace_back(fs);
//         }

//         for (auto it = e["attr"].cbegin(); it != e["attr"].cend(); ++it)
//         {
//            fe->attr_[std::stoi(it.key())] = it.value();
//         }


//         vec.emplace_back(fe);
//     }
// }



// bool Fight::__startFight(const char *team)
// {
//     nlohmann::json js = nlohmann::json::parse(team);

//     std::vector<FightEntity*> vec;
//     parse(vec, js["team1"], 1);
//     parse(vec, js["team2"], 2);

    

//     std::sort(vec.begin(), vec.end(), sortByAttrKeyValue);

//     uint8_t round = 0;
//     uint8_t maxRound = js["round"];
//     for (auto &e : vec)
//     {
//         if(!e->canAttack())
//         {
//             continue;
//         }
//         e->attack(vec);

//         if(round++ >maxRound)
//         {
//             break;
//         }
//     }

//     return true;
// }

// void Fight::start(uint64_t uid, const char *team)
// {

//     bool res = __startFight(team);

//     Task t;
//     t.opt_ = ConType::ConType_fight_res;
//     t.sessionId_ = uid;
//     t.fightRes = res;
//     std::unique_lock<std::mutex> lk(gMutex);
//     gQueue.emplace(std::move(t));
//     lk.unlock();
//     gCondVar.notify_one();
    
// }