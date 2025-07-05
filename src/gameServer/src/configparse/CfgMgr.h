

#pragma once
#include "../../../common/Singleton.h"
#include "../../../common/CommDefine.h"

#include <unordered_map>
#include <vector>
#include <string>

struct ItemCfg
{
    int id_;
    bool stack_;
    uint8_t itemType_;
};



struct SkillCfg
{
    struct Group
    {
        struct Result
        {
            uint8_t centerPosType_;
            uint8_t targetCount_;
            uint8_t identical_;
            uint16_t rate_;
            uint8_t type_;
            int p1_;
            int p2_;
            int p3_;
            int p4_;
            int p5_;
            int p6_;
        };
        uint8_t type_;
        std::unordered_map<uint32_t, Result> result_;
    };

    uint32_t id_;
    uint8_t type_;
    Group *group_;
    uint8_t useRound_; // 第几回合释放
    uint8_t cd_;
    std::unordered_map<uint16_t, uint32_t> attr_;
};

struct BuffCfg
{
    struct Trigger
    {
        uint8_t type_;
        int p1_;
        int p2_;
        int p3_;
        int p4_;
    };

    uint32_t id_;
    uint32_t group_;
    uint8_t duration_;
    uint8_t overlapMaxLayer_;
    uint8_t delay_;
    uint8_t num_;
    uint8_t dispel_;
    uint8_t dead_;
    uint8_t type_;
    uint32_t subType_;
    uint8_t judgeType_;
    int time_;
    uint16_t rate_;
    int p1_;
    int p2_;
    int p3_;
    int p4_;
    int p5_;
    int p6_;
    Trigger* trigger_;
};

struct MonsterCfg
{
    uint32_t id_;
    std::string name_;
    uint32_t skin_;
    uint8_t job_;
    uint8_t star_;
    uint8_t step_;
    uint8_t color_;
    uint32_t level_;
    uint64_t power_;
    uint8_t pos_;
    std::vector<uint32_t> skills_;
    std::unordered_map<uint16_t, uint32_t> attr_;
};

struct MonsterGroupCfg
{
    uint32_t id_;
    std::unordered_map<int8_t, uint32_t> monster_;
};

class CfgMgr : public Singleton<CfgMgr>
{
public:
    ~CfgMgr();
    ItemCfg *getItemCfg(uint32_t id);
    bool isHero(uint32_t itemId);
    void loadItem(const char *str);
    void loadJsonCfg(const std::string& path);
    MonsterGroupCfg *existGroup(uint32_t groupId);
    MonsterCfg* existMonster(uint32_t monsterId);
    SkillCfg *getSkillCfg(uint16_t skillId);

public:
    std::unordered_map<uint32_t, ItemCfg>
        itemList_;
    std::unordered_map<uint32_t, SkillCfg> skillCfg_;
    std::unordered_map<uint32_t, BuffCfg> buffCfg_;
    std::unordered_map<uint32_t, MonsterGroupCfg> monsterGroup_; 
    std::unordered_map<uint32_t, MonsterCfg> monsterCfg_; 
};

#define gCfgMgr CfgMgr::instance()