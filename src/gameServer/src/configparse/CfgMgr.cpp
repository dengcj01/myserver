

#include "CfgMgr.h"

#include <iostream>
#include <fstream>

#include "../../../common/Json.hpp"
#include "../../../common/log/Log.h"


CfgMgr::~CfgMgr()
{
}

ItemCfg *CfgMgr::getItemCfg(uint32_t id)
{
    auto it = itemList_.find(id);
    if(it == itemList_.end())
    {
        return 0;
    }

    return &it->second;
}

SkillCfg *CfgMgr::getSkillCfg(uint16_t skillId)
{
    auto it = skillCfg_.find(skillId);
    return it != skillCfg_.end() ? (&it->second) : nullptr;
}

bool CfgMgr::isHero(uint32_t itemId)
{
    ItemCfg *ic = getItemCfg(itemId);
    if(!ic)
    {
        return false;
    }

    return ic->itemType_ == ItemTypeDefine::ItemTypeDefine_hero;
}

    void CfgMgr::loadItem(const char *str)
{
    nlohmann::json js = nlohmann::json::parse(str);
    uint32_t id = js["uid"];

    ItemCfg it;
    it.id_ = id;
    it.stack_ = false;
    uint8_t stack = js["stack"];

    it.stack_ = stack == 1 ? true : false;

    itemList_.emplace(id, std::move(it));
}

MonsterGroupCfg *CfgMgr::existGroup(uint32_t groupId)
{
    auto it = monsterGroup_.find(groupId);
    if(it == monsterGroup_.end())
    {
        return nullptr;
    }

    return &(it->second);
}

MonsterCfg* CfgMgr::existMonster(uint32_t monsterId)
{
    auto it = monsterCfg_.find(monsterId);
    if (it == monsterCfg_.end())
    {
        return nullptr;
    }

    return &(it->second);
}

void CfgMgr::loadJsonCfg(const std::string &path)
{
    std::string s = path + "logic/config/";

    std::ifstream bufCfg(s.append("BuffConfig.json"));
    nlohmann::json js;
    bufCfg >> js;
    for(auto& e: js.items())
    {
        BuffCfg cfg;
        auto &val = e.value();

        cfg.id_ = val["uid"];
        cfg.group_ = val["group"];
        cfg.duration_ = val["duration"];
        cfg.overlapMaxLayer_ = val["overlapMaxLayer"];
        cfg.delay_ = val["delay"];
        cfg.num_ = val["num"];
        cfg.dispel_ = val["dispel"];
        cfg.dead_ = val["dead"];
        cfg.type_ = val["type"];
        cfg.subType_ = val["subType"];
        cfg.judgeType_ = val["judgeType"];
        cfg.time_ = val["time"];
        cfg.rate_ = val["rate"];
        cfg.p1_ = val["param1"];
        cfg.p2_ = val["param2"];
        cfg.p3_ = val["param3"];
        cfg.p4_ = val["param4"];
        cfg.p5_ = val["param5"];
        cfg.p6_ = val["param6"];

        if (val.find("trigger") != val.end())
        {
            cfg.trigger_ = new BuffCfg::Trigger();
            for (const auto &trigger : val["trigger"].items())
            {
                auto &tri = trigger.value();
                cfg.trigger_->type_ = tri["type"];
                cfg.trigger_->p1_ = tri["param1"];
                cfg.trigger_->p2_ = tri["param2"];
                cfg.trigger_->p3_ = tri["param3"];
                cfg.trigger_->p4_ = tri["param4"];
            }
        }
        buffCfg_.emplace(val["uid"], std::move(cfg));
    }
    js.clear();
    s.clear();
    s = path + "logic/config/";

    std::ifstream skillCfg(s.append("Skillconfig.json"));
    skillCfg >> js;
    for (auto it = js.begin(); it != js.end(); ++it)
    {
        std::string key = it.key();
        nlohmann::json val = it.value();

        SkillCfg cfg;
        cfg.id_ = val["uid"];
        cfg.type_ = val["skillType"];

        if (val.find("group") != val.end())
        {
            cfg.group_ = new SkillCfg::Group();
            for (auto &group : val["group"].items())
            {
                auto &val1 = group.value();
                cfg.group_->type_ = val1["groupType"];

                for (auto &result : val1["result"].items())
                {
                    auto &val2 = result.value();
                    SkillCfg::Group::Result _result;
                    _result.centerPosType_ = val2["centerPosType"];
                    _result.targetCount_ = val2["targetCount"];
                    _result.identical_ = val2["identical"];
                    _result.rate_ = val2["rate"];
                    _result.type_ = val2["type"];
                    _result.p1_ = val2["param1"];
                    _result.p2_ = val2["param2"];
                    _result.p3_ = val2["param3"];
                    _result.p4_ = val2["param4"];
                    _result.p5_ = val2["param5"];
                    _result.p6_ = val2["param6"];

                    std::string key1 = result.key();
                    uint32_t rid = std::stoi(key1);

                    cfg.group_->result_.emplace(rid, std::move(_result));
                }
            }
        }

        skillCfg_.emplace(val["uid"], std::move(cfg));
    }
    js.clear();
    s.clear();
    s = path + "logic/config/";

    std::ifstream monsterGroupCfg(s.append("Monstergroupconfig.json"));
    monsterGroupCfg >> js;
    for (auto &entry : js.items())
    {
        MonsterGroupCfg cfg;
        auto &val = entry.value();
        cfg.id_ = val["uid"];

        for (auto &monster : val["monsters"])
        {
            cfg.monster_.emplace(monster["posidx"], monster["monid"]);

        }

        monsterGroup_.emplace(val["uid"], std::move(cfg));
    }
    js.clear();
    s.clear();
    s = path + "logic/config/";

    std::ifstream monsterCfg(s.append("Monsterconfig.json"));
    monsterCfg >> js;
    for (auto &entry : js.items())
    {
        auto &val = entry.value();
        MonsterCfg cfg;
        cfg.job_ = val["job"];
        cfg.skin_ = val["skinId"];
        cfg.star_ = val["star"];
        cfg.step_ = val["step"];
        cfg.color_ = val["color"];
        cfg.level_ = val["level"];
        cfg.power_ = val["power"];
        cfg.id_ = val["uid"];

        for (auto &skill : val["skills"])
        {
            cfg.skills_.emplace_back(skill);
        }

        for (auto &attr : val["attrs"])
        {
            cfg.attr_.emplace(attr["type"], attr["value"]);
        }

        monsterCfg_.emplace(val["uid"], std::move(cfg));
    }
    js.clear();
    s.clear();
    s = path + "logic/config/";

    // std::ifstream monsterCfg1(s.append("Monsterconfig1.json"));

    // monsterCfg1 >> js;
}
