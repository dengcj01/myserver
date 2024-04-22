

// #include "FightEntity.h"
// #include "FightSkill.h"

// #include "../../../common/log/Log.h"
// #include "../../../common/CommDefine.h"

// bool FightEntity::canAttack()
// {
//     if(death_)
//     {
//         return false;
//     }

//     return true;
// }

// void FightEntity::attack(std::vector<FightEntity*>& vec)
// {
//     FightSkill *fs = nullptr;
//     for (auto &e : skills_)
//     {
//         if(e->useRound_==round_)
//         {
//             fs = e;
//             break;
//         }
//     }

//     if(fs)
//     {
//         std::vector<FightEntity *> vec = fs->findTarget(vec);
//         fs->skillEffect(vec);
//     }
// }

// std::tuple<uint8_t, int> FightEntity::updateAttr(uint8_t attrId, int attrVal)
// {
//     auto it = attr_.find(attrId);
//     if(it == attr_.end())
//     {
//         logInfo("FightEntity::updateAttr err id:%d attrid:%d", id_, attrId);
//         return std::make_tuple(attrId, -1);
//     }

//     it->second += attrVal;

//     if(it->second <= 0)
//     {
//         it->second = 0;
//     }

//     return std::make_tuple(attrId, it->second);
// }

// bool FightEntity::isDeath(uint8_t attrId, int val)
// {
//     return attrId == AttrTypeDefine::AttrTypeDefine_hp && val <= 0;
// }