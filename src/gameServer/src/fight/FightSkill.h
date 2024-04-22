

// #pragma once
// #include <stdint.h>
// #include "FightEntity.h"
// #include <vector>
// #include "../configparse/CfgMgr.h"

// class FightSkill
// {

// public:
//     FightSkill(uint16_t id);
//     std::vector<FightEntity*> findTarget(std::vector<FightEntity*> &vec);
//     void skillEffect(std::vector<FightEntity *> &vec);
//     std::vector<FightEntity *> checkTriggerBuff();
//     FightEntity *fe_;
//     uint8_t useRound_ = 0; // 第几回合释放
//     const SkillCfg* cfg_; // 技能配置
// };