

// #pragma once


// #include <vector>
// #include <tuple>
// #include <unordered_map>

// class FightSkill;
// class FightBuff;


// class FightEntity
// {
// public:
//     void attack(std::vector<FightEntity*>& vec);
//     bool canAttack();
//     void death() {death_ = true;}
//     std::tuple<uint8_t, int> updateAttr(uint8_t attrId, int attrVal);
//     bool isDeath(uint8_t attrId, int val);
//     uint32_t id_;
//     bool death_ = false;
//     uint8_t round_;
//     uint8_t pos_;
//     uint8_t teamId_;
//     std::vector<FightSkill *> skills_;
//     std::vector<FightBuff *> buff_;
//     std::unordered_map<uint8_t, int> attr_;
// };