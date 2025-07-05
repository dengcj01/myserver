local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"
local playermoduledata = require "common.playermoduledata"
local util = require "common.util"
local heroConfig = require "logic.config.hero"
local itemConfig = require "logic.config.itemConfig"
local systemConfig = require "logic.config.system"
local fightLevelupConfig = require "logic.config.fightLevelup"
local equipConfig = require "logic.config.equip"
local equipLevelupConfig = require "logic.config.equipLevelup"
local equipAttributeCfg = require "logic.config.equipAttribute"
local courseSystemConfig = require "logic.config.courseSystemConfig"
local courseLevelupConfig = require "logic.config.courseLevelupConfig"
local skillConfig = require "logic.config.skill"
local talentConfig = require "logic.config.talent"
local heroConfig = require "logic.config.hero"

local bagsystem = require "logic.system.bagsystem"
local tasksystem = require "logic.system.tasksystem"
local dropsystem = require "logic.system.dropsystem"
local heroattributesystem = require "logic.system.hero.heroattributesystem"

local herosystem = {}

local equipPosDefine = {
    equipMinPos = 1, -- 英雄装备最小孔位
    equipMaxPos = 6 -- 英雄装备最大孔位
}

local heroUpOpt = 
{
    level =1, -- 升级
    step = 2, -- 升阶
}

-- 命座升级提升的技能类型定义
local skillType =
{
    normal=1, -- 普攻
    skill=2, -- 战技
    passive=3, -- 被动
}

-- 学习奖励领取找到
local studyRdStatus =
{
    noRecv=1, -- 未领取
    recv=2, -- 已领取
}


local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.hero)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.hero)
end

local function getCacheSpaceData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.cacheSpace)
end

local function saveCacheSpaceData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.cacheSpace)
end

local function PackOneHeroInfo(heroId, heroData)
    local heroId = tonumber(heroId)
    local cfg = heroConfig[heroId] or {}
    if (heroData.level or 0) <= 0 then
        heroData.level = 1
    end

    local t = {
        id = heroId,
        name = heroData.name or cfg.name,
        exp = heroData.exp or 0,
        state = heroData.state or 0,
        grade = heroData.grade or 0,
        level = heroData.level,
        constellation = heroData.constellation or 0,
        studyLv = heroData.studyLv,

        studyData = {},
        equipt = {},
        talent = {}
    }

    local talent = t.talent
    local cacheTalent = heroData.talent or {}

    talent.skillBasic = cacheTalent.skillBasic or 1
    talent.skillCombat = cacheTalent.skillCombat or 1
    talent.skillPassive = cacheTalent.skillPassive or 1
    talent.skillExtra1 = cacheTalent.skillExtra1 or 0
    talent.skillExtra2 = cacheTalent.skillExtra2 or 0
    talent.skillExtra3 = cacheTalent.skillExtra3 or 0
    talent.talentArrange = cacheTalent.talentArrange or 0
    talent.talentAttribute1 = cacheTalent.talentAttribute1 or 0
    talent.talentAttribute2 = cacheTalent.talentAttribute2 or 0
    talent.talentAttribute3 = cacheTalent.talentAttribute3 or 0
    talent.talentAttribute4 = cacheTalent.talentAttribute4 or 0
    talent.talentAttribute5 = cacheTalent.talentAttribute5 or 0
    talent.talentAttribute6 = cacheTalent.talentAttribute6 or 0
    talent.talentAttribute7 = cacheTalent.talentAttribute7 or 0
    talent.talentAttribute8 = cacheTalent.talentAttribute8 or 0
    talent.talentAttribute9 = cacheTalent.talentAttribute9 or 0
    talent.talentAttribute10 = cacheTalent.talentAttribute10 or 0
    talent.talentNature = cacheTalent.talentNature or 1

    local studyData = t.studyData

    for k, v in pairs(heroData.studyData or {}) do
        table.insert(studyData, {id = tonumber(k), process = v})
    end

    return t
end

local function packHeros(heroList)
    local msgs = {}
    for k, v in pairs(heroList) do
        local msg = PackOneHeroInfo(k, v)
        table.insert(msgs, msg)
    end

    return msgs
end


function herosystem.checkHasHero(player, id)
    id = tostring(id)
    local data = getData(player)
    local list = data.heroList or {}
    if list[id] then
        return true
    end

    return false
end



function herosystem.getHeroById(player, id)
    id = tostring(id or 0)
    local data = getData(player)
    local list = data.heroList or {}

    return list[id]
end

local function ChangeHeroItem(player, heros, items)
    local datas = getData(player)
    if not datas then
        return
    end

    local have = tools.clone(datas.have or {})
    for heroId, cnt in pairs(heros) do
        local config = heroConfig[heroId]

        local sid = tostring(heroId)
        local heroData = have[sid]
        local heroMultipleAcquisition = config.heroMultipleAcquisition
        local cid = heroMultipleAcquisition[2]
        local ccnt = heroMultipleAcquisition[3] or 1
        if not heroData then
            have[sid] = 1
            heros[heroId] = 1
            cnt = cnt - 1

            if cnt > 0 then
                items[cid] = (items[cid] or 0) + cnt * ccnt
            end
        else
            items[cid] = (items[cid] or 0) + cnt * ccnt
            heros[heroId] = nil
        end
    end
end

local function AddHeros(player, pid, itemList, heroRd, extra)
    local datas = getData(player)
    if not datas then
        print("AddHeros no datas", pid)
        return
    end

    if next(itemList) == nil then
        return
    end

    datas.lvData = datas.lvData or {}
    local lvData = datas.lvData

    datas.heroList = datas.heroList or {}
    local heroList = datas.heroList

    datas.tputong = datas.tputong or {}
    local tputong = datas.tputong

    datas.tzhanji = datas.tzhanji or {}
    local tzhanji = datas.tzhanji

    datas.tbeidong = datas.tbeidong or {}
    local tbeidong = datas.tbeidong

    datas.active = datas.active  or {}
    local active = datas.active

    datas.have = datas.have or {}
    local have = datas.have

    local newList = {}

    _G.HeroAttrData[pid] = _G.HeroAttrData[pid] or {}   
    local attrData = _G.HeroAttrData[pid]

    for heroId, _ in pairs(itemList) do
        local sid = tostring(heroId)
        local studyLv = 1
        local studyData = {}
        local rds = {}
        have[sid] = 1
        local info =
        {
            level = 1,
            id = heroId,
            talent = 
            {
                skillBasic = 1,
                skillCombat = 1,
                skillPassive = 1,
                talentNature = 1
            },
            studyData = studyData,
            studyLv = studyLv,
            rds = rds
        }

        local cfg = courseSystemConfig[studyLv]
        if cfg then
            for _, v in pairs(cfg.courseContent) do
                studyData[tostring(v)] = 0
            end
        end


        heroList[sid] = info

        newList[sid] = info

        local slv = tostring(1)
        lvData[slv] = (lvData[slv] or 0) + 1
        tools.accRdCount(heroRd, heroId, 1)

        tbeidong[slv] = (tbeidong[slv] or 0) + 1
        tzhanji[slv] = (tzhanji[slv] or 0) + 1
        tputong[slv] = (tputong[slv] or 0) + 1

        tasksystem.updateProcess(player, pid, define.taskType.heroAllLv, {1}, define.taskValType.cover, nil, nil, {ret=lvData})

        heroattributesystem.addNewHeroAttr(attrData, heroId, info)
    end


    for sid, _ in pairs(active) do
        local id = tonumber(sid)
        local activeCfg = courseLevelupConfig[id]
        if activeCfg then
            local activateHero = activeCfg.activateHero
            if next(activateHero) == nil then
                for heroId, _ in pairs(itemList) do
                    local heroData = heroList[tostring(heroId)]
                    heroData.studyData[sid] = 0
                end
            else
                for _, heroId in pairs(activateHero) do
                    local res = itemList[heroId]
                    if res then
                        local heroData = heroList[tostring(heroId)]
                        heroData.studyData[sid] = 0
                    end
                end
            end
        end
    end


    saveData(player)

    if next(newList) then
        local msgs = {}
        msgs.hero = packHeros(newList)
        net.sendMsg2Client(player, ProtoDef.NotifyAddNewHero.name, msgs)
    end

end

local function ReqHeroList(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqHeroList no datas", pid)
        return
    end

    local msgs = {}

    msgs.hero = packHeros(datas.heroList or {})


    net.sendMsg2Client(player, ProtoDef.ResHeroList.name, msgs)
end

local function getHeroLevelMax(level, grade)
    local sheetUpgradeLevel = systemConfig[0].upgradeLevel
    local levelMax = sheetUpgradeLevel[#sheetUpgradeLevel]
    -- 已达到最高级
    if level == levelMax then
        return levelMax
    end
    return sheetUpgradeLevel[grade + 1]
end

local function getHeroLevelByExp(exps, originlevel, levelMax)
    local addLevel = 0
    local data = fightLevelupConfig[originlevel + addLevel]
    if not data or not data.nextLevelExp then
        return 0, 0
    end

    while exps >= data.nextLevelExp do
        addLevel = addLevel + 1
        exps = exps - data.nextLevelExp

        -- 溢出经验转道具发放
        if (originlevel + addLevel) >= levelMax then
            return (originlevel + addLevel), exps
        end
        data = fightLevelupConfig[originlevel + addLevel]
    end

    return (originlevel + addLevel), exps
end

local function ReqHeroLevelUp(player, pid, proto)
    local heroId, itemlist = proto.heroId, proto.itemlist
    local datas = getData(player)
    if not datas then
        print("ReqHeroLevelUp no datas", pid)
        return
    end
    local costList = {}
    for k, v in pairs(itemlist) do
        if v.count > 0 then
            table.insert(costList, {
                type = v.type,
                count = v.count,
                id = v.id
            })
        end
    end


    local heroList = datas.heroList
    if not heroList then
        print("ReqHeroLevelUp no heroList", pid)
        return
    end

    local sid = tostring(heroId)
    local theHero = heroList[sid]
    if not theHero then
        print("ReqHeroLevelUp no theHero", pid, sid)
        return
    end

    if next(costList) == nil then
        print("ReqHeroLevelUp no itemlist", pid, sid)
        return
    end

    local exps = 0

    for i, v in pairs(costList) do
        local config = itemConfig[v.id]
        if not config or config.usage ~= 1 then
            print("ReqHeroLevelUp no cfg", pid)
            return
        end

        if not bagsystem.checkItemEnough(player, {v}) then
            print("ReqHeroLevelUp item no enough", pid)
            return
        end
        exps = exps + config.param * v.count
    end
    if (theHero.level or 0) <= 0 then
        theHero.level = 1
    end

    local level = theHero.level
    local levelMax = getHeroLevelMax(level, theHero.grade or 0)

    if level == levelMax then
        print("ReqHeroLevelUp max lv", pid, heroId)
        return
    end

    local exp = theHero.exp or 0
    local ntotalexp = exp + exps

    local heroLevel, heroExp = getHeroLevelByExp(ntotalexp, level, levelMax)

    -- 检测 扣除货币
    local costGoldId = systemConfig[0].levelCostGold[1]
    local costGoldValue = systemConfig[0].levelCostGold[2] * exps

    -- 满级不计算溢出经验消耗金币
    if heroLevel == levelMax then
        costGoldValue = systemConfig[0].levelCostGold[2] * (exps - heroExp)
    end

    local costCurrency = {
        id = costGoldId,
        type = define.itemType.currency,
        count = math.ceil(costGoldValue)
    }
    if not bagsystem.checkItemEnough(player, {costCurrency}) then
        print("ReqHeroLevelUp item no currency", pid)
        return
    end

    table.insert(costList, costCurrency)

    if not bagsystem.costItems(player, costList) then
        print(pid .. "hero level cost not enough heroid :" .. heroId)
        return
    end

    theHero.level = heroLevel
    theHero.exp = heroExp
    local resultMsg = {
        itemlist = {}
    }

    -- 溢出经验转道具发放
    if theHero.level == levelMax then
        local offet_exp = theHero.exp
        theHero.exp = 0

        local itemId = systemConfig[0].itemExpHeroRe
        local expItemConfig = itemConfig[itemId]
        local value = math.floor(offet_exp / expItemConfig.param)

        if value > 0 and expItemConfig then
            bagsystem.addItems(player, {{
                id = expItemConfig.id,
                type = define.itemType.item,
                count = value
            }})

        end
    end

    saveData(player)

    resultMsg.heroId = heroId
    resultMsg.level = heroLevel
    resultMsg.exp = theHero.exp

    net.sendMsg2Client(player, ProtoDef.ResHeroLevelUp.name, resultMsg)

    tasksystem.updateProcess(player, pid, define.taskType.upHeroLevelOrStep, {1}, define.taskValType.add, {heroUpOpt.level})

    datas.lvData = datas.lvData or {}
    local lvData= datas.lvData
    --tools.ss(lvData)

    local slv = tostring(heroLevel)
    lvData[slv] = (lvData[slv] or 0) + 1
    local splv = tostring(level)
    lvData[splv] = lvData[splv] - 1
    if lvData[splv] == 0 then
        lvData[splv] = nil
    end

    heroattributesystem.cacheHeroAttr(player, pid, {sid}, datas)

    _G.gluaFuncChangeWorkShopEffect(player, pid, heroId)
    tasksystem.updateProcess(player, pid, define.taskType.heroAllLv, {1}, define.taskValType.cover, nil, nil, {ret=lvData})
end

local function ReqHeroUpgrade(player, pid, proto)
    local heroId = proto.heroId
    local datas = getData(player)
    if not datas then
        print("ReqHeroUpgrade no datas", pid)
        return
    end

    local heroList = datas.heroList
    if not heroList then
        print("ReqHeroUpgrade no heroList", pid)
        return
    end

    local sid = tostring(heroId)
    local theHero = heroList[sid]
    if not theHero then
        print("ReqHeroUpgrade no theHero", pid, sid)
        return
    end

    local heroconfig = heroConfig[heroId]
    if not heroconfig then
        print("ReqHeroUpgrade no heroconfig", pid, sid)
        return
    end

    local grade = theHero.grade or 0
    local nextGrade = grade + 1
    local leveMax = systemConfig[0].upgradeLevel[nextGrade]
    if not leveMax then
        -- 已达到最高阶
        print("ReqHeroUpgrade max grade", pid, heroId)
        return
    end

    local level = theHero.level or 1
    if level < leveMax then
        print(pid .. "hero level min :" .. level .. "heroId:" .. heroId)
        return
    end

    local itemlist = {}
    local upgradeCoin = heroconfig.upgradeCoin[nextGrade]

    for i, data in pairs(upgradeCoin) do
        local type = define.itemType.item
        if data[1] <= define.currencyType.max and  data[1] > define.currencyType.none then
            type = define.itemType.currency
        end

        table.insert(itemlist, {
            id = data[1],
            count = data[2],
            type = type
        })
    end

    if not bagsystem.checkAndCostItem(player, itemlist) then
        print("ReqHeroUpgrade no item", pid, heroId)
        return
    end

    theHero.grade = grade + 1

    saveData(player)
    local msgs = {
        heroId = heroId,
        grade = theHero.grade
    }
    net.sendMsg2Client(player, ProtoDef.ResHeroUpgrade.name, msgs)

    tasksystem.updateProcess(player, pid, define.taskType.upHeroLevelOrStep, {1}, define.taskValType.add, {heroUpOpt.step})
end


--- 检测天赋是否已经满级
local function checkTalentLevelMax(heroId, talentName, level)
    level = level or 0
    if talentName == "skillBasic" or talentName == "skillCombat" or talentName == "skillPassive" then
        local skillId = heroConfig[heroId][talentName]
        local skillConfig = skillConfig[skillId]
        return level >= (#skillConfig.levelCost + 1)
    else
        return level >= 1
    end
end

function herosystem.checkHasHeroTalent(player, heroid, name)
    local datas = getData(player)
    if not datas then
        return false
    end

    local heroList = datas.heroList
    if not heroList then
        return false
    end

    local sid = tostring(heroid)
    local theHero = heroList[sid]
    if not theHero then
        return false
    end

    return (theHero.talent[name] or 0) > 0
end

local function ReqHeroUnlockTalent(player, pid, proto)
    local heroId, talentname = proto.heroId, proto.talentname
    local datas = getData(player)
    if not datas then
        print("ReqHeroUnlockTalent no datas", pid)
        return
    end

    local heroList = datas.heroList
    if not heroList then
        print("ReqHeroUnlockTalent no heroList", pid)
        return
    end

    local sid = tostring(heroId)
    local theHero = heroList[sid]
    if not theHero then
        print("ReqHeroUnlockTalent no theHero", pid, sid)
        return
    end

    local talentLevel = theHero.talent[talentname]
    if checkTalentLevelMax(heroId, talentname, talentLevel) then
        -- 已解锁
        print("ReqHeroUnlockTalent yet lock", pid, sid)
        return
    end

    local hConfig = heroConfig[heroId]
    if not hConfig then
        print("ReqHeroUnlockTalent hero config not fnd", pid, heroId)
        return
    end

    local condition = hConfig[talentname] and hConfig[talentname][1]
    if not condition or not condition[2] then
        -- 未找到天赋数据
        print("ReqHeroUnlockTalent not find condition", pid, heroId, talentname)
        return
    end

    local tconfig = talentConfig[condition[2]]
    if not tconfig then
        -- 未找到解锁天赋数据
        print("ReqHeroUnlockTalent no talentconfig", pid, heroId, talentname)
        return
    end

    if (theHero.level or 0) <= 0 then
        theHero.level = 1
    end

    local level = theHero.level or 0
    if level < tconfig.lv then
        -- 等级不足
        print("ReqHeroUnlockTalent lv no enough", pid, heroId, talentname, level)
        return
    end

    local grade = theHero.grade or 0
    if grade < tconfig.upgrade then
        -- 阶级不足
        print("ReqHeroUnlockTalent grade no enough", pid, heroId, talentname, grade)
        return
    end

    local talent = theHero.talent or {}
    if not talent[tconfig.unlockName] or talent[tconfig.unlockName] < 1 then
        -- 前置天赋未解锁
        print("ReqHeroUnlockTalent no ulocl pre talent", pid, heroId, talentname, grade)
        return
    end

    local itemlist = {}
    local itemType = define.itemType.item
    local currencyType = define.itemType.currency
    local maxCurrency = define.currencyType.max
    local costCfg = hConfig[talentname]
    local maxLen = #costCfg
    for i=2, maxLen do
        local data = costCfg[i]
        local type = itemType

        local id = data[1]
        if id <= maxCurrency then
            type = currencyType
        end

        table.insert(itemlist, {
            id = id,
            type = type,
            count = data[2]
        })
    end

    if not bagsystem.checkAndCostItem(player, itemlist) then
        return
    end 

    theHero.talent[talentname] = 1



    local msgs = {
        heroId = heroId,
        talentname = talentname
    }
    net.sendMsg2Client(player, ProtoDef.ResHeroUnlockTalent.name, msgs)

    tasksystem.updateProcess(player, pid, define.taskType.upTalentLv, {1}, define.taskValType.add)



    saveData(player)

    if talentname == 'talentArrange' then
        tasksystem.updateProcess(player, pid, define.taskType.heroJingyingLv, {1}, define.taskValType.add)
    end
    
end


local function ReqHeroUpgradeConstell(player, pid, proto)
    if not proto then
        print("ReqHeroUpgradeConstell proto param is null", pid)
        return
    end

    local heroId = proto.heroId

    local datas = getData(player)
    if not datas then
        print("ReqHeroUpgradeConstell no datas", pid)
        return
    end

    local heroList = datas.heroList
    if not heroList then
        print("ReqHeroUpgradeConstell no heroList", pid)
        return
    end

    local sid = tostring(heroId)
    local theHero = heroList[sid]
    if not theHero then
        print("ReqHeroUpgradeConstell no theHero", pid, sid)
        return
    end

    local hConf = heroConfig[heroId]
    local constellation = theHero.constellation or 0
    if constellation >= #hConf.starUpName then
        -- 满命座
        print("ReqHeroUpgradeConstell max constellation", pid, sid)
        return
    end

    local nextLv = constellation + 1

    local cost = hConf.starUpMaterial[nextLv]

    if not bagsystem.checkAndCostItem(player, {{id=cost[2],type=cost[1],count=cost[3]}}) then
        print("ReqHeroUpgradeConstell items not enough", pid, sid, heroId)
        return
    end

    theHero.constellation = nextLv


    net.sendMsg2Client(player, ProtoDef.ResHeroUpgradeConstell.name, {
        heroId = heroId,
        constellation = nextLv
    })


    datas.tmingzuo = datas.tmingzuo or {}
    local tmingzuo = datas.tmingzuo
    local snextLv = tostring(nextLv)
    if constellation > 0 then
        local sconstellation = tostring(constellation)
        tmingzuo[sconstellation] = tmingzuo[sconstellation] - 1
    end

    tmingzuo[snextLv] = (tmingzuo[snextLv] or 0) + 1



    tasksystem.updateProcess(player, pid, define.taskType.heroMingzuoLv, {1}, define.taskValType.cover, nil, nil, {ret=tmingzuo})

    local talent = theHero.talent
    for _, v in pairs(hConf.starUpSkillLv or {}) do
        local addLevel = v[1]
        if nextLv == addLevel then
            local addType = v[2]


            local taskType = nil
            local mdata = nil
            local nowLv = 0
            if addType == skillType.normal then
                taskType = define.taskType.heroPuGongLv
                mdata = datas.tputong 
                nowLv = talent["skillBasic"]
            elseif addType == skillType.skill then
                taskType = define.taskType.heroZhanjiLv
                mdata = datas.tzhanji
                nowLv = talent["skillCombat"]
            elseif addType == skillType.passive then
                taskType = define.taskType.heroBeiDongLv
                mdata = datas.tbeidong
                nowLv = talent["skillPassive"]
            end

            if mdata then
                local addVal = v[3]
                local snowLv = tostring(nowLv)
                local cnt = mdata[snowLv] or 0
                if cnt > 0 then
                    mdata[snowLv] = cnt - 1
                    nowLv = nowLv + addVal
                    snowLv = tostring(nowLv)
                    mdata[snowLv] = (mdata[snowLv] or 0) + 1
                end

                tasksystem.updateProcess(player, pid, taskType, {1}, define.taskValType.cover, nil, nil, {ret=mdata})
            end
        end


    end

    saveData(player)
end

local function ReqHeroUpgradeSkill(player, pid, proto)
    local heroId, talentname = proto.heroId, proto.talentname

    local datas = getData(player)
    if not datas then
        print("ReqHeroUpgradeSkill no datas", pid)
        return
    end

    local heroList = datas.heroList
    if not heroList then
        print("ReqHeroUpgradeSkill no heroList", pid)
        return
    end

    local sid = tostring(heroId)
    local theHero = heroList[sid]
    if not theHero then
        print("ReqHeroUpgradeSkill no theHero", pid, sid)
        return
    end

    local hconf = heroConfig[heroId]
    if not hconf then
        print("ReqHeroUpgradeSkill no heroconfig", pid, heroId)
        return
    end

    local talent = theHero.talent
    if not talent then
        print("ReqHeroUpgradeSkill no talent", pid, heroId)
        return
    end

    local talentLevel = talent[talentname] or 0
    local skillid = hconf[talentname]
    if not skillid then
        print("ReqHeroUpgradeSkill no talent skillid", pid, heroId, talentname)
        return
    end

    if checkTalentLevelMax(heroId, talentname, talentLevel) then
        -- 已满级
        print("ReqHeroUpgradeSkill max lv", pid, heroId, talentname)
        return
    end

    local skillconfig = skillConfig[skillid]
    if not skillconfig then
        print("ReqHeroUpgradeSkill no skillconfig", pid, heroId, talentname, skillid)
        return
    end

    local grade = theHero.grade or 0
    if grade < skillconfig.upgradeLimit[talentLevel] then
        print("ReqHeroUpgradeSkill grade no enough", pid, heroId, talentname, skillid, grade)
        return
    end

    local levelCost = skillconfig.levelCost
    local itemlist = {}

    for i, data in pairs(levelCost[talentLevel]) do
        local type = define.itemType.item
        if data[1] <= define.currencyType.max and  data[1] > define.currencyType.none then
            type = define.itemType.currency
        end
        table.insert(itemlist, {
            id = data[1],
            count = data[2],
            type = type
        })
    end

    if not bagsystem.checkAndCostItem(player, itemlist) then
        return
    end

    local nextLv = talentLevel + 1
    talent[talentname] = nextLv



    net.sendMsg2Client(player, ProtoDef.ResHeroUpgradeSkill.name, {
        heroId = heroId,
        level = talent[talentname],
        talentname = talentname
    })

    tasksystem.updateProcess(player, pid, define.taskType.upTalentLv, {1}, define.taskValType.add)



    local snextLv = tostring(nextLv)
    local stalentLevel = tostring(talentLevel)

    local taskType = nil
    local mdata = {}
    local addType = nil
    local mingzuoLv = theHero.constellation or 0
    local addval = 0

    if talentname == "skillCombat" then
        addType = skillType.skill
        mdata = datas.tzhanji
    elseif talentname == "skillPassive" then
        addType = skillType.passive
        mdata = datas.tbeidong
    else
        addType = skillType.normal
        mdata = datas.tputong
    end

    local starUpSkillLv = hconf.starUpSkillLv
    for k, v in ipairs(starUpSkillLv or {}) do
        if addType == v[2] and mingzuoLv >= v[1] then
            addval = v[3]
            break
        end
    end

    -- 先还原命座加成的
    if addval > 0 then
        mdata[stalentLevel] = (mdata[stalentLevel] or 0) + 1
        local newAddVal = addval + talentLevel
        local saddval = tostring(newAddVal)
        mdata[saddval] = mdata[saddval] - 1
    end


    -- 在算升级的
    if talentname == "skillCombat" then
        taskType = define.taskType.heroZhanjiLv
        mdata[snextLv] = (mdata[snextLv] or 0) + 1

    elseif talentname == "skillPassive" then
        taskType = define.taskType.heroBeiDongLv
        mdata[snextLv] = (mdata[snextLv] or 0) + 1
    else
        taskType = define.taskType.heroPuGongLv
        mdata[snextLv] = (mdata[snextLv] or 0) + 1
    end

    if talentLevel > 0 then
        local stalentLevel = tostring(talentLevel)
        local oldVal = mdata[stalentLevel] or 0
        if oldVal > 0 then
            mdata[stalentLevel] = mdata[stalentLevel] - 1
        end
    end


    if addval > 0 then
        local cnt = mdata[snextLv]
        mdata[snextLv] = cnt - 1
        nextLv = nextLv + addval
        snextLv = tostring(nextLv)
        mdata[snextLv] = (mdata[snextLv] or 0) + 1
    end

    tasksystem.updateProcess(player, pid, taskType, {1}, define.taskValType.cover, nil, nil, {ret=mdata})

    saveData(player)

    
end

local function onEquipAndOff(player, pid, suid, heroid, cacheSpaceData, isReplace, isSave)
    local equipData = bagsystem.getItemInfo(player, pid, suid)
    if not equipData then
        print("onEquipAndOff no equipData", pid, suid)
        return
    end

    if equipData.ownerType ~= define.itemType.hero then
        print("onEquipAndOff not hero", pid, suid)
        return      
    end

    if isSave == nil then
        isSave = true
    end

    local cnt = cacheSpaceData.equipSpace
    if not isReplace then
        if cnt <= 0 then
            print("onEquipAndOff no space", pid)
            return
        end
        
        if isSave then
            cacheSpaceData.equipSpace = cnt - 1
            saveCacheSpaceData(player)
        end

    end

    if isSave then
        equipData.owner = nil
        equipData.idx = nil
        equipData.ownerType = nil
    
        playermoduledata.saveData(player, define.playerModuleDefine.bag)
    end

    
    if not isReplace then
        net.sendMsg2Client(player, ProtoDef.ResHeroEquipOff.name, { heroId = heroid, eid = suid})
    end
    
    
    return true
end

local function ReqHeroEquipOn(player, pid, proto)
    local heroId, equipSlotNum, eid, oldUid = proto.heroId, proto.equipSlotNum, proto.eid, proto.oldUid
    local datas = getData(player)
    if not datas then
        print("ReqHeroEquipOn no datas", pid)
        return
    end

    local heroList = datas.heroList
    if not heroList then
        print("ReqHeroEquipOn no heroList", pid)
        return
    end

    local sid = tostring(heroId)
    local theHero = heroList[sid]
    if not theHero then
        print("ReqHeroEquipOn no theHero", pid, sid)
        return
    end

    local equipData = bagsystem.getItemInfo(player, pid, eid)
    if not equipData then
        print("ReqHeroEquipOn no equipData", pid, eid, heroId)
        return
    end

    local equipId = equipData.id
    local cfg = equipConfig[equipId]
    if not cfg then
        print("ReqHeroEquipOn no cfg", pid, eid, heroId, equipId)
        return
    end

    local furnList = {}
    local owner = equipData.owner
    if owner then
        if equipData.ownerType ~= define.itemType.furniture then
            print("ReqHeroEquipOn have owner", pid, eid, owner, heroId)
            return
        end

        furnList[owner] = {eid}
    end

    if equipSlotNum < equipPosDefine.equipMinPos or equipSlotNum > equipPosDefine.equipMaxPos then
        print("ReqHeroEquipOn pos err", pid, heroId, equipSlotNum)
        return
    end

    local cacheSpaceData = getCacheSpaceData(player)
    if not cacheSpaceData then
        print("ReqHeroEquipOn no cacheSpaceData", pid, eid, owner, heroId)
        return
    end

    local idx = equipData.idx or 0
    if owner == sid and idx == equipSlotNum then
        print("ReqHeroEquipOn no repeat on", pid, eid, owner, heroId, equipSlotNum)
        return
    end


    theHero.equipList = theHero.equipList or {}
    local equipList = theHero.equipList
    local sequipSlotNum = tostring(equipSlotNum)

    if oldUid ~= "" then
        local ret = onEquipAndOff(player, pid, oldUid, heroId, cacheSpaceData, true)
        if ret ~= true then
            return
        end

        equipList[oldUid] = nil

    else
        cacheSpaceData.equipSpace = cacheSpaceData.equipSpace + 1
        saveCacheSpaceData(player)
    end


    if next(furnList) then
        _G.gluaFuncDeleteFurnEquip(player, furnList)
    end
    
    equipList[eid] = 1

    equipData.owner = sid
    equipData.idx = equipSlotNum
    equipData.ownerType = define.itemType.hero
    
    playermoduledata.saveData(player, define.playerModuleDefine.bag)

    net.sendMsg2Client(player, ProtoDef.ResHeroEquipOn.name, {
        heroId = heroId,
        eid = eid,
        equipSlotNum = equipSlotNum,
        oldUid = oldUid,
    })


    saveData(player)
    

    local kind = bagsystem.getEquipKind(cfg.portion)
    local pos = bagsystem.getEquipPos(cfg.portion)
    tasksystem.updateProcess(player, pid, define.taskType.takonEquip, {1}, define.taskValType.add, {cfg.equipQuality,kind,pos,equipId})
end

local function ReqHeroEquipOff(player, pid, proto)
    local heroId, eid = proto.heroId, proto.eid
    local datas = getData(player)
    if not datas then
        print("ReqHeroEquipOff no datas", pid)
        return
    end

    local heroList = datas.heroList
    if not heroList then
        print("ReqHeroEquipOff no heroList", pid)
        return
    end

    local sid = tostring(heroId)
    local theHero = heroList[sid]
    if not theHero then
        print("ReqHeroEquipOff no theHero", pid, sid)
        return
    end

    local equipData = bagsystem.getItemInfo(player, pid, eid)
    if not equipData then
        print("ReqHeroEquipOff no equipData", pid, eid)
        return
    end

    local owner = equipData.owner
    if not owner then
        print("ReqHeroEquipOff no owner", pid, eid, heroId)
        return
    end


    local cacheSpaceData = getCacheSpaceData(player)
    if not cacheSpaceData then
        print("ReqHeroEquipOff no cacheSpaceData", pid)
        return
    end

    local equipList = theHero.equipList
    if not equipList then
        print("ReqHeroEquipOff no equipList", pid)
        return
    end


    local res = onEquipAndOff(player, pid, eid, heroId, cacheSpaceData, false)
    if res == true then
        equipList[eid] = nil
        saveData(player)
    end

end



local function getDivisibleByFive(value, step)
    if value % step == 0 then
        return value
    else
        return math.floor(value / step) * step
    end
end

local function ReqEquipLevelUp(player,pid,proto)
    local uid, itemlist, uids, heroId = proto.uid, proto.itemlist, proto.uids, proto.heroId

    local equip = bagsystem.getItemInfo(player, pid, uid)
    if not equip then
        print("ReqEquipLevelUp no equip", pid, uid)
        return
    end

    local equipId = equip.id
    local equipCfg = equipConfig[equipId]
    if not equipCfg then
        print("ReqEquipLevelUp not equipCfg", pid, equipId)
        return 
    end

    local nowQuality = equipCfg.equipQuality
    if nowQuality <= 1 then
        print("ReqEquipLevelUp no quality", pid, equipId)
        return 
    end

    local addExp = 0
    local costExp = 0
    local sub = {} 
    for k, v in pairs(itemlist) do
        local id = v.id
        local config = itemConfig[id]
        if not config then
            print("ReqEquipLevelUp no itemcfg", pid, id)
            return
        end

        local count = v.count
        if count <= 0 then
            print("ReqEquipLevelUp count <= 0", pid, id)
            return
        end

        addExp = addExp + config.param * count
    end

    local itemType = define.itemType.equip
    local otherCfg = systemConfig[0]
    local equipExp = otherCfg.equipExp
    local equipGainExp = otherCfg.equipGainExp
    local delList = {}
    local equipListExp = 0
    for k, v in pairs(uids) do
        local item = bagsystem.getItemInfo(player, pid, v)
        if not item then
            print("ReqEquipLevelUp no item", pid, v)
            return
        end

        if item.owner then
            print("ReqEquipLevelUp have master", pid, v)
            return
        end

        local id = item.id
        local cfg = equipConfig[id]
        if not cfg then
            print("ReqEquipLevelUp no cfg", pid, id)
            return
        end

        local quality = cfg.equipQuality
        if quality <= 1 then
            print("ReqEquipLevelUp no quality1", pid, equipId)
            return 
        end

        local lv = item.level or 0
        local exp = item.exp or 0

        if lv > 0 then
            table.insert(sub, lv)

            local equipLvCfg = equipLevelupConfig[quality]
            if not equipLvCfg then
                print("ReqEquipLevelUp not equipLvCfg1", pid, equipId)
                return 
            end

            local expCfg = equipLvCfg.Exp

            for i=1, lv do
                local val = expCfg[i] or 0
                exp = exp + val
            end
        end

        local expVal = (cfg.sellValue * equipExp + exp) * equipGainExp
        equipListExp = equipListExp + expVal

        delList[id] = delList[id] or {}
        local del = delList[id]
        table.insert(del, v)
    end

    addExp = addExp + math.ceil(equipListExp)

    --print("aaaaaaaaaaaaa",math.ceil(equipListExp))

    --addExp = 1000
    if addExp == 0 then
        print("ReqEquipLevelUp no exp", pid)
        return
    end


    if heroId > 0 and equip.owner ~= tostring(heroId) then
        print("ReqEquipLevelUp hero no match", pid, uid, heroId, equip.owner)
        return
    end


    local equipLvCfg = equipLevelupConfig[nowQuality]
    if not equipLvCfg then
        print("ReqEquipLevelUp not equipLvCfg", pid, equipId)
        return 
    end

    local expCfg = equipLvCfg.Exp
    if not expCfg or next(expCfg) == nil then
        print("ReqEquipLevelUp not expCfg", pid, equipId)
        return 
    end

    local nowLv = equip.level or 0
    local nextExp = expCfg[nowLv + 1]
    if not nextExp then
        print("ReqEquipLevelUp not nextExp not", pid, equipId, nowLv)
        return 
    end

    local curExp = equip.exp or 0
    local totalExp = addExp + curExp

    costExp = addExp

    local nextLv = nowLv
    while totalExp >= nextExp do
        nextLv = nextLv + 1
        totalExp = totalExp - nextExp
        if totalExp <= 0 then
            break
        end

        nextExp = expCfg[nextLv + 1]
        if not nextExp then
            break
        end
    end


    local costCfg = otherCfg.levelCostGoldEquip
    if not costCfg then
        print("ReqEquipLevelUp no costCfg", pid)
        return 
    end

    if totalExp <= 0 then
        totalExp = 0
    end

    local maxExpLen = #expCfg
    if nextLv >= maxExpLen then
        -- 处理升级到满级的金币扣除数量
        local atNextLv = nowLv + 1
        nextExp = expCfg[atNextLv]
        costExp = nextExp - curExp
        if atNextLv ~= maxExpLen then
            local startIdx = atNextLv + 1
            for i=startIdx, maxExpLen  do
                costExp = costExp + expCfg[i]
            end
        end
    end

    local costGoldId = costCfg[1]
    local costGoldValue = math.ceil(costCfg[2] * costExp)

    local costGold = {{id = costGoldId, type = define.itemType.currency, count = costGoldValue}}
    if not bagsystem.checkAndCostItem(player,  costGold) then
        return 
    end

    equip.exp = totalExp
    equip.level = nextLv

    if nextLv >= maxExpLen then
        equip.exp = 0

        if totalExp > 0 then
            local itemId = otherCfg.itemExpEpuiqRe
            local expItemConfig = itemConfig[itemId]
            if expItemConfig then
                local val = expItemConfig.param
                if val > 0 then
                    local value = math.floor(totalExp / val)
                    if value > 0 then
                        bagsystem.addItems(player, {{id = itemId, type = define.itemType.item, count = value}})
                    end
                end
            end
        end
    end

    local attrs = equip.attrs or {}
    local mainId = equip.mainId
    local smainId = tostring(mainId)
    local eAttrCfg = equipAttributeCfg[mainId]
    if eAttrCfg then
        if nextLv ~= nowLv then
            for i=nowLv+1, nextLv do
                attrs[smainId] = attrs[smainId] + (math.floor(eAttrCfg.addition * 10000)) 
            end
            
        end    
    end
 
    local step = otherCfg.attributeUp

    if step > 0 then
        local lvcnt1 = getDivisibleByFive(nowLv, step)
        local lvcnt2 = getDivisibleByFive(nextLv, step)
        local lvcnt3 = lvcnt2 - lvcnt1

    
        if lvcnt3 > 0 then
            local addCnt = math.floor(lvcnt3 / step)
            local eAttrCfg = equipAttributeCfg[mainId]
            if not eAttrCfg then
                print("ReqEquipLevelUp no eAttrCfg", pid, mainId)
            else
    
                local subCnt = equip.subCnt
                local limitCnt = otherCfg.initialAttributesLimit[nowQuality]
                local clist = {}
                local weihtTab = {}
                local filterList = {mainId}
                local filterTypeList = {eAttrCfg.type}
                local attribute = equipCfg.Attribute
                for k, v in pairs(attribute) do
                    weihtTab[v[1]] = v[2]
                end
        
        
                local maxWeight = 0
                for k, v in pairs(attrs) do
                    local cid = tonumber(k)
                    if cid ~= mainId then
                        local weight = weihtTab[cid]
                        if weight then
                            table.insert(clist, {cid, weight + maxWeight})
                            maxWeight = weight + maxWeight
                        end
                    end
                end 

                for i=1, addCnt do
                    if subCnt >= limitCnt then
                        if maxWeight > 0 then
                            local rval = math.random(1, maxWeight)
                            for k, v in ipairs(clist) do
                                if rval <= v[2] then
                                    local cid = v[1]
                                    local eAttrCfg = equipAttributeCfg[cid]
                                    if eAttrCfg then
                                        local range = eAttrCfg.range
                                        local val1 = range[1] * 10000
                                        local val2 = range[2] * 10000
                                        local attrVal = math.random(val1, val2)
                                        local scid = tostring(cid)
                                        attrs[scid] = attrs[scid] + attrVal
                                    end
                                    break
                                end
                            end
                        end
                    else
                        local tab = {}
                        local cloneWeihtTab = tools.clone(weihtTab)
                        for kk, _ in pairs(attrs) do
                            local nkk = tonumber(kk)
                            if cloneWeihtTab[nkk] then
                                cloneWeihtTab[nkk] = nil
                            end
                        end

                        local retTab = tools.formatWeightTabByHash(cloneWeihtTab)
                    
                        local id, value = bagsystem.addSubAttr(equipId, retTab, filterList, filterTypeList)
                        if id ~= nil then
                            attrs[tostring(id)] = value
                            local newCnt = subCnt + 1
                            equip.subCnt = newCnt
                            subCnt = newCnt

                            clist = {}
                            maxWeight = 0
                            for k, v in pairs(attrs) do
                                local cid = tonumber(k)
                                if cid ~= mainId then
                                    local weight = weihtTab[cid]
                                    if weight then
                                        table.insert(clist, {cid, weight + maxWeight})
                                        maxWeight = weight + maxWeight
                                    end
                                end
                            end 
                        end
                    end
                end
            end
    
        end
    end


    bagsystem.costItems(player, itemlist)
    bagsystem.deleteEquipByUid(player, pid, delList)

    playermoduledata.saveData(player, define.playerModuleDefine.bag)

    
    local msgs = {guid = uid, level = nextLv, exp = equip.exp, heroId = heroId}
    msgs.attrs = bagsystem.packEquipAttr(attrs)

    net.sendMsg2Client(player, ProtoDef.ResEquipLevelUp.name, msgs)

    if nowLv > 0 then
        table.insert(sub, nowLv)
    end


    local equipLvData = {}
    if nowLv ~= nextLv then
        equipLvData = bagsystem.updateEqupLvData(player, {nextLv}, sub)
    end


    tasksystem.updateProcess(player, pid, define.taskType.getEquipLvCnt, {1}, define.taskValType.cover, nil, nil, {ret=equipLvData})
    tasksystem.updateProcess(player, pid, define.taskType.upEquipLevel, {1}, define.taskValType.add)
end


local function ReqHeroStudy(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqHeroStudy no datas", pid)
        return
    end

    local heroList = datas.heroList
    if not heroList then
        print("ReqHeroStudy no heroList", pid)
        return
    end

    local heroId = proto.heroId
    local id = proto.id
    local cnt = proto.cnt

    if cnt < 1 or cnt > 5 then
        print("ReqHeroStudy cnt err", pid)
        return
    end

    local heroCfg = heroConfig[heroId]
    if not heroCfg then
        print("ReqHeroStudy no heroCfg", pid)
        return
    end


    local sHeroId= tostring(heroId)
    local heroData = heroList[sHeroId]
    if not heroData then
        print("ReqHeroStudy no heroData", pid)
        return
    end
    
    local studyLv = heroData.studyLv

    local studyData = heroData.studyData
    local sid = tostring(id)    

    local lvCfg = courseSystemConfig[studyLv]
    if not lvCfg then
        print("ReqHeroStudy no lvCfg", pid)
        return
    end

    local studyCfg = courseLevelupConfig[id]
    if not studyCfg then
        print("ReqHeroStudy no studyCfg", pid)
        return
    end
    
 
    local upCondition = lvCfg.upCondition
    if not upCondition then
        print("ReqHeroStudy no upCondition", pid)
        return
    end

    local maxLvCondition = studyCfg.maxLvCondition 

    local process = studyData[sid]
    if process >= maxLvCondition then
        printf("ReqHeroStudy process level max", pid)
        return
    end

    local upExpend = studyCfg.upExpend
    local upExpendList = {}
    for k, v in pairs(upExpend) do
        table.insert(upExpendList, {id=v[2],count=v[3]*cnt,type=v[1]})
    end

    if not bagsystem.checkAndCostItem(player, upExpendList) then
        print("ReqHeroStudy no item", pid)
        return
    end
    
    heroData.rds = heroData.rds or {}
    local rds = heroData.rds
    rds[sid] = rds[sid] or {}
    local rd = rds[sid]

    local upEmp = studyCfg.upEmpirical
    local talentNature = heroCfg.talentNature
    local extraEmpirical = studyCfg.extraEmpirical

    for k, v in pairs(extraEmpirical) do
        if v[1] == talentNature then
            upEmp = upEmp + v[2]
            break
        end
    end

    local attrOk = false
    local nextProcess = process
    local proficiency = studyCfg.proficiency

    for i = 1, cnt do
        local ok = false
        for j = 1, upEmp do
            nextProcess = nextProcess + 1

            local sNextProcess = tostring(nextProcess)

            local proCfg = proficiency[nextProcess]
            if proCfg then
                if rd[sNextProcess] == nil and (next(proCfg.reward) or proCfg.productReward > 0) then
                    rd[sNextProcess] = studyRdStatus.noRecv
                end

                local attReward = proCfg.attReward
                if next(attReward) and heroattributesystem.addHeroAttr(pid, heroId, attReward[1], attReward[2]) > 0 then
                    attrOk = true
                end
            end

            if nextProcess >= maxLvCondition then
                ok = true
                break
            end
        end

        if ok then
            break
        end
    end

    studyData[sid] = nextProcess

    local courseContent = lvCfg.courseContent

    local nextStudyLv = studyLv
    if studyCfg.type == define.studyType.normal and studyLv < #courseSystemConfig then
        local ok = true
        for k, v in ipairs(courseContent) do
            if studyData[tostring(v)] < upCondition[k] then
                ok = false
                break
            end
        end

        if ok then
            nextStudyLv = studyLv + 1
            heroData.studyLv = nextStudyLv

            local upLvCfg = courseSystemConfig[nextStudyLv]
            local upCourseContent = upLvCfg.courseContent

            for _, i in pairs(upCourseContent) do
                studyData[tostring(i)] = 0
            end
        end

    end

    saveData(player)

    local ids = {}

    for k, v in pairs(rd) do
        if v == studyRdStatus.noRecv then
            table.insert(ids, tonumber(k))
        end
    end
    
    local msgs = {}
    msgs.heroId = heroId
    msgs.id = id
    msgs.cnt = cnt
    msgs.process = nextProcess
    msgs.studyLv = nextStudyLv
    msgs.ids = ids

    net.sendMsg2Client(player, ProtoDef.ResHeroStudy.name, msgs)

    if attrOk then
        _G.gluaFuncChangeWorkShopEffect(player, pid, heroId)
    end
end

local function ReqHeroStudyRewardInfo(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqHeroStudyRewardInfo no datas", pid)
        return
    end

    local heroList = datas.heroList
    if not heroList then
        print("ReqHeroStudyRewardInfo no heroList", pid)
        return
    end


    local msgs = {data = {}}
    local data = msgs.data

    for k, v in pairs(heroList) do
        local rds = v.rds
        local ids = {} 

        for studyId, rewardData in pairs(rds) do
            local recvMsg = {}
            
            for process, status in pairs(rewardData) do
                if status == studyRdStatus.noRecv then
                    table.insert(recvMsg, tonumber(process))
                end
            end

            table.insert(ids, {studyId = tonumber(studyId), ids = recvMsg})
        end

        table.insert(data, {heroId = tonumber(k), ids = ids})
    end

    net.sendMsg2Client(player, ProtoDef.ResHeroStudyRewardInfo.name, msgs)
end

local function ReqRecvHeroStudyProcessRd(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqRecvHeroStudyProcessRd no datas", pid)
        return
    end

    local heroList = datas.heroList
    if not heroList then
        print("ReqRecvHeroStudyProcessRd no heroList", pid)
        return
    end

    local heroId = proto.heroId
    local id = proto.id
    local process = proto.process

    local sHeroId= tostring(heroId)
    local heroData = heroList[sHeroId]
    if not heroData then
        print("ReqRecvHeroStudyProcessRd no heroData", pid)
        return
    end

    local rewardCfg = courseLevelupConfig[id]
    if not rewardCfg then
        print("ReqRecvHeroStudyProcessRd no rewardCfg", pid)
        return
    end


    local rds = heroData.rds or {}
    local sProcess = tostring(process)
    local sid = tostring(id)
    local rdData = rds[sid] or {}
    local status = rdData[sProcess]

    if not status or status == studyRdStatus.recv then
        print("ReqRecvHeroStudyProcessRd recved", pid, status)
        return
    end

    local proficiency = rewardCfg.proficiency
    if not proficiency then
        print("ReqRecvHeroStudyProcessRd no proficiency", pid)
        return
    end

    local proficiencyData = proficiency[process]
    local reward = proficiencyData.reward

    if next(reward) then
        local rd = dropsystem.getDropItemList(reward)

        bagsystem.addItems(player, rd)
    end


    local productReward = proficiencyData.productReward
    if productReward > 0 then
        local cfg = itemConfig[productReward]
        if cfg == nil then
            print("ReqRecvHeroStudyProcessRd no cfg", pid)
            return
        end

        local convenientPurchase = cfg.convenientPurchase

        if next(convenientPurchase) then
            if not bagsystem.checkAndCostItem(player, {{id=convenientPurchase[2], type=convenientPurchase[1],count=convenientPurchase[3]}}) then
                print("ReqRecvHeroStudyProcessRd no item", pid)
                return
            end
        end

        bagsystem.addItems(player, {{id=productReward,type=define.itemType.item,count=1}})
    end

    rdData[sProcess] = studyRdStatus.recv

    saveData(player)

    local msgs = {}
    msgs.heroId = heroId
    msgs.id = id
    msgs.process = process

    net.sendMsg2Client(player, ProtoDef.ResRecvHeroStudyProcessRd.name, msgs)
end


local function ReqResetHeroStudy(player, pid, proto)

    local datas = getData(player)
    if not datas then
        print("ReqResetHeroStudy no datas", pid)
        return
    end

    local heroList = datas.heroList
    if not heroList then
        print("ReqResetHeroStudy no heroList", pid)
        return
    end

    local sHeroId= proto.heroId
    
    local heroData = heroList[sHeroId]
    if not heroData then
        print("ReqResetHeroStudy no heroData", pid)
        return
    end

    local studyData = heroData.studyData

    local ok = true
    for k, v in pairs(studyData) do
        if v > 0 then
            ok = false
            break
        end
    end

    if ok then
        print("ReqResetHeroStudy process zero", pid)
        return
    end

    local studyLv = heroData.studyLv

    local reCfg = courseSystemConfig[studyLv]
    if not reCfg then
        print("ReqResetHeroStudy no reCfg", pid)
        return
    end

    local resetExpend = reCfg.resetExpend

    local itemlist = {}
    table.insert(itemlist, {
        id = resetExpend[2],
        count = resetExpend[3],
        type = resetExpend[1]
    })

    if not bagsystem.checkAndCostItem(player, itemlist) then
        print("ReqResetHeroStudy no item", pid)
        return
    end
    
    local heroId = tonumber(sHeroId)

    local heroCfg = heroConfig[heroId]
    if not heroCfg then
        print("ReqResetHeroStudy no heroCfg", pid)
        return
    end

    local talentNature = heroCfg.talentNature

    local idItem = {}
    for k, v in pairs(studyData) do
        if v > 0 then

            local expendCfg = courseLevelupConfig[tonumber(k)]
            if not expendCfg then
                print("ReqResetHeroStudy no expendCfg", pid)
                return
            end
            
            local upEmp = expendCfg.upEmpirical
            local extraEmpirical = expendCfg.extraEmpirical

            for _, value in pairs(extraEmpirical) do
                if value[1] == talentNature then
                    upEmp = upEmp + value[2]
                    break
                end
            end

            local upExpendList = expendCfg.upExpend
            for _, upExpend in pairs(upExpendList) do
                local sid = tostring(upExpend[2])
                if idItem[sid] == nil then
                    idItem[sid] = {type = upExpend[1], id = upExpend[2], count = upExpend[3] * math.ceil(v / upEmp)}
                else
                    idItem[sid].count = idItem[sid].count + upExpend[3] * math.ceil(v / upEmp)
                end
            end
        end
    end
    
    local resetRestitution = reCfg.resetRestitution / 100

    for _, v in pairs(idItem) do
        v.count = math.floor(v.count * resetRestitution)
    end

    itemlist = {}
    for _, v in pairs(idItem) do
        table.insert(itemlist, v)
    end
    bagsystem.addItems(player, itemlist)

    local nextLv = 1
    heroData.studyLv = nextLv

    heroData.studyData = {}
    studyData = heroData.studyData

    local reNextCfg = courseSystemConfig[nextLv]
    if not reNextCfg then
        print("ReqResetHeroStudy no reNextCfg", pid)
        return
    end

    local courseContent = reNextCfg.courseContent
    for _, v in ipairs(courseContent) do
        studyData[tostring(v)] = 0
    end

    local active = datas.active
    for sid, _ in pairs(active) do
        local id = tonumber(sid)

        local expendCfg = courseLevelupConfig[id]
        if not expendCfg then
            print("ReqResetHeroStudy no expendCfg", pid)
            return
        end

        local activateHero = expendCfg.activateHero
        if next(activateHero) == nil then
            studyData[sid] = 0
        else
            for _, v in ipairs(activateHero) do
                if v == heroId then
                    studyData[sid] = 0
                    break
                end
            end
        end
    end

    saveData(player)

    local msgs = {heroId = heroId, data = studyData}
    
    net.sendMsg2Client(player, ProtoDef.ResResetHeroStudy.name, msgs)

    heroattributesystem.cacheHeroAttr(player, pid, {sHeroId}, datas)

    _G.gluaFuncChangeWorkShopEffect(player, pid, heroId)
end


local function ReqOneKeyHeroEquip(player, pid, proto)
    local datas = getData(player)
    local heroList = datas.heroList or {}
    local heroId = proto.heroId
    local sid = tostring(proto.heroId)
    local heroData = heroList[sid]

    if not heroData then
        print("ReqOneKeyHeroEquip", pid, heroId)
        return
    end

    local data = proto.data
    if next(data) == nil then
        print("ReqOneKeyHeroEquip no data", pid, heroId)
        return
    end

    local cacheSpaceData = getCacheSpaceData(player)
    if not cacheSpaceData then
        print("ReqOneKeyHeroEquip no cacheSpaceData", pid, heroId)
        return
    end

    heroData.equipList = heroData.equipList or {}
    local equipList = heroData.equipList

    local furnList = {}
    local addCnt = 0
    for k, v in pairs(data) do
        local pos = v.pos
        local eid = v.eid
        
        local spos = tostring(pos)

        local equipData = bagsystem.getItemInfo(player, pid, eid)
        if not equipData then
            print("ReqOneKeyHeroEquip no equipData", pid, eid, heroId)
            return
        end

        local equipId = equipData.id
        local cfg = equipConfig[equipId]
        if not cfg then
            print("ReqOneKeyHeroEquip no cfg", pid, eid, heroId, equipId)
            return
        end
    
        local owner = equipData.owner
        if owner then
            if equipData.ownerType ~= define.itemType.furniture then
                print("ReqOneKeyHeroEquip have owner", pid, eid, owner, heroId)
                return
            end
    
            furnList[owner] = furnList[owner] or {}
            local fdata = furnList[owner]
            table.insert(fdata, eid)
        end

        if pos < equipPosDefine.equipMinPos or pos > equipPosDefine.equipMaxPos then
            print("ReqOneKeyHeroEquip pos err", pid, heroId, pos)
            return
        end

        local idx = equipData.idx or 0
        if owner == sid and idx == pos then
            print("ReqOneKeyHeroEquip no repeat on", pid, eid, owner, heroId, pos)
            return
        end
        
        local oldId = v.oldId
        if oldId ~= "" then
            local ret = onEquipAndOff(player, pid, oldId, heroId, cacheSpaceData, true, false)
            if ret ~= true then
                return
            end
        else
            addCnt = addCnt + 1
        end

    end

    if next(furnList) then
        _G.gluaFuncDeleteFurnEquip(player, furnList)
    end

    for k, v in pairs(data) do
        local pos = v.pos
        local eid = v.eid
        
        local equipData = bagsystem.getItemInfo(player, pid, eid)
        local spos = tostring(pos)
        local oldId = v.oldId
        if oldId ~= "" then
            onEquipAndOff(player, pid, oldId, heroId, cacheSpaceData, true, true)
            equipList[oldId] = nil
        end

        equipList[eid] = 1

        equipData.owner = sid
        equipData.idx = pos
        equipData.ownerType = define.itemType.hero

        local equipId = equipData.id
        local cfg = equipConfig[equipId]

        local kind = bagsystem.getEquipKind(cfg.portion)
        local pos = bagsystem.getEquipPos(cfg.portion)
        tasksystem.updateProcess(player, pid, define.taskType.takonEquip, {1}, define.taskValType.add, {cfg.equipQuality,kind,pos,equipId})
    end

    playermoduledata.saveData(player, define.playerModuleDefine.bag)

    if addCnt > 0 then
        cacheSpaceData.equipSpace = cacheSpaceData.equipSpace + addCnt
        saveCacheSpaceData(player)
    end

    saveData(player)

    net.sendMsg2Client(player, ProtoDef.ResOneKeyHeroEquip.name, proto)
end



local function AddStudyId(player, pid, id, cnt)
    local datas = getData(player)
    if not datas then
        print("AddStudyId no datas", pid)
        return
    end

    local heroList = datas.heroList
    if not heroList then
        print("AddStudyId no heroList", pid)
        return
    end

    local activeCfg = courseLevelupConfig[id]
    if not activeCfg then
        print("AddStudyId no activeCfg", pid)
        return 
    end
    
    local itemlist = {}
    table.insert(itemlist, {
        id = id,
        count = cnt,
        type = define.itemType.item
    })
    if not bagsystem.checkAndCostItem(player, itemlist) then
        print("AddStudyId no item", pid)
        return
    end

    local activateHero = activeCfg.activateHero
    local sid = tostring(id)

    if next(activateHero) == nil then
        --全部英雄添加培养点
        for k, v in pairs(heroList) do
            v.studyData[sid] = 0
        end

    else
        --指定英雄添加培养点
        for k, v in pairs(activateHero) do
            local heroData = heroList[tostring(v)]
            if heroData then
                heroData.studyData[sid] = 0
            end
        end
    end

    datas.active[sid] = 1

    saveData(player)

    local msgs = {}
    msgs.id = id

    net.sendMsg2Client(player, ProtoDef.NotifyAddStudyProcess.name, msgs)
end


local function gmReqHeroStudy(player, pid, args)
    pid = 72103438924469
    player = gPlayerMgr:getPlayerById(pid)
    --ReqHeroStudyRewardInfo(player, pid, {heroId=3,id=2,cnt=5})
    --ReqHeroStudy(player, pid, {heroId=1,id=1,cnt=5})
    --ReqResetHeroStudy(player, pid, {heroId = 1})
    --ReqRecvHeroStudyProcessRd(player, pid, {heroId=1,id=1,process=30})
    --addStudyId(player, pid, 8004)
    local heroData = getData(player)
    PackOneHeroInfo(player, heroData)
end

local function gmReqHeroStudy1(player, pid, args)
    --[[
    pid = 72103324729447
    player = gPlayerMgr:getPlayerById(pid)
    local datas = playermoduledata.getData(player, define.playerModuleDefine.test)

    playermoduledata.saveData(player, define.playerModuleDefine.test)
    ]]

end



local function gmLogin1(player, pid, args)
    pid = 72103438924469
    player = gPlayerMgr:getPlayerById(pid)
    ReqHeroStudyRewardInfo(player, pid) 
end

local function gmAddHeightItem(player, pid, args)
    -- pid = 72105050956738
    -- player = gPlayerMgr:getPlayerById(pid)

    local list = {}
    for k, v in pairs(itemConfig) do
        if v.type == define.itemSubType.rareMaterial then
            table.insert(list, {id = k, count = 111, type = define.itemType.item})
        end
    end

    table.insert(list, {id = 5103, count = 100000, type = define.itemType.item})

    bagsystem.addItems(player, list)
end

local function gmAddAllHeros(player, pid, args)
    pid = args[1]
    player = gPlayerMgr:getPlayerById(pid)
    local tab = {}
    for i = 1, 30 do
        table.insert(tab, {id = i, count = 1, type = define.itemType.hero})
    end

    bagsystem.addItems(player, tab)
end


_G.gLuaFuncPackOneHeroInfo = PackOneHeroInfo
_G.gluaFuncAddHeros = AddHeros
_G.gluaFuncChangeHeroItem = ChangeHeroItem
_G.gluaFuncAddStudyId = AddStudyId 

gm.reg("gmReqHeroStudy", gmReqHeroStudy)
gm.reg("gmReqHeroStudy1", gmReqHeroStudy1)
gm.reg("gmLogin1", gmLogin1)
gm.reg("gmAddHeightItem", gmAddHeightItem)
gm.reg("gmAddAllHeros", gmAddAllHeros)

net.regMessage(ProtoDef.ReqHeroList.id, ReqHeroList, net.messType.gate)
net.regMessage(ProtoDef.ReqHeroLevelUp.id, ReqHeroLevelUp, net.messType.gate)
net.regMessage(ProtoDef.ReqHeroUpgrade.id, ReqHeroUpgrade, net.messType.gate)
net.regMessage(ProtoDef.ReqHeroUnlockTalent.id, ReqHeroUnlockTalent, net.messType.gate) -- 解锁经营天赋
net.regMessage(ProtoDef.ReqHeroUpgradeConstell.id, ReqHeroUpgradeConstell, net.messType.gate)
net.regMessage(ProtoDef.ReqHeroUpgradeSkill.id, ReqHeroUpgradeSkill, net.messType.gate)
net.regMessage(ProtoDef.ReqHeroEquipOn.id, ReqHeroEquipOn, net.messType.gate)
net.regMessage(ProtoDef.ReqHeroEquipOff.id, ReqHeroEquipOff, net.messType.gate)
net.regMessage(ProtoDef.ReqEquipLevelUp.id, ReqEquipLevelUp, net.messType.gate)
net.regMessage(ProtoDef.ReqHeroStudy.id, ReqHeroStudy, net.messType.gate)
net.regMessage(ProtoDef.ReqHeroStudyRewardInfo.id, ReqHeroStudyRewardInfo, net.messType.gate)
net.regMessage(ProtoDef.ReqRecvHeroStudyProcessRd.id, ReqRecvHeroStudyProcessRd, net.messType.gate)
net.regMessage(ProtoDef.ReqResetHeroStudy.id, ReqResetHeroStudy, net.messType.gate)
net.regMessage(ProtoDef.ReqOneKeyHeroEquip.id, ReqOneKeyHeroEquip, net.messType.gate)


return herosystem



