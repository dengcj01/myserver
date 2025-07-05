
local tools = require "common.tools"
local gm = require("common.gm")
local util = require "common.util"
local net = require "common.net"
local GachaConfig = require "logic.config.gacha"
local GachaDropConfig = require "logic.config.gachaDropConfig"
local bagsystem = require "logic.system.bagsystem"
local define = require "common.define"
local herosystem = require "logic.system.hero.herosystem"
local playermoduledata = require "common.playermoduledata"
local heroConfig = require "logic.config.hero"
local msgCode = require "common.model.msgerrorcode"
local tasksystem = require "logic.system.tasksystem"
local furnituresystem = require "logic.system.furnituresystem"

-- 抽取卡牌类型
local gachaType = {
    hero = 1,
    furniture = 2
}

local lowType = {
    small = 0, -- 小保底
    big = 1 -- 大保底
}

local cardPoolType = {
    newbie = 1, -- 1.新手卡池 
    comm = 2, -- 2.通用卡池
    limited = 3 -- 3.限定卡池
}
local ruleType = {
    comm = 0,  -- "普通掉落"
    newbie =1, --新手保底掉落"
    xpump = 2, --x抽保底"
    small =  3, --小保底"
    big = 4, -- "大保底"
}

local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.gacha)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.gacha)
end

local function getDataByid(player, type)
    local id = type
    type = tostring(type)
    local gachaData = getData(player)
    if not gachaData[type] then
        gachaData[type] = {
            type = id,
            count = 0,
            turn = 0,
            heroid = 0,
            totalCnt = 0
        }
    end

    return gachaData[type]
end

local function writepackage(player, id)
    local msg = {}
    if not id then
        return msg
    end
    local data = getDataByid(player, id)
    msg.count = data.count or 0
    msg.heroid = data.heroid or 0
    msg.type = data.type or 0
    msg.totalCnt = data.totalCnt or 0
    msg.turn = data.turn or 0

    return msg
end

local function sendGachaData(player, pid, data, id)
    if not data then
        data = {}
    end

    local res = {}
    res.gachaData = writepackage(player, id)
    res.dropStringList = data

    net.sendMsg2Client(player, ProtoDef.ResStartGacha.name, res)
end


local function getGachaCount(config, isOneTime)
    local count = 1
    if not isOneTime then
        count = 10
    end

    return count
end

local function addCount(player, id, count)
    if (count or 0) <= 0 then
        return
    end
    local data = getDataByid(player, id)
    data.count = (data.count or 0) + count
end

local function clearDataByid(player, id)
    local data = getDataByid(player, id)
    data.count = 0
end

local function randDropPool(config, count, dropGroup, dropWeight)
    local incrNum = count - config.probIncrStartNum + 1
    dropWeight = tools.clone(dropWeight)
    if incrNum >= 1 then
        local dropGroupIndex = tools.getItemIndex(dropGroup, config.probIncrDropGroup)
        if dropGroupIndex > 0 then
            dropWeight[dropGroupIndex] = dropWeight[dropGroupIndex] + config.probIncrVal * incrNum
        end
    end
    local dropGroupPool = {}
    for i, groupId in ipairs(dropGroup) do
        local weight = dropWeight[i]
        table.insert(dropGroupPool, {
            groupId = groupId,
            weight = weight
        })
    end

    local resultGroupData = util.randomByWeight(dropGroupPool, "weight")
    if not resultGroupData then
        resultGroupData = dropGroupPool[1]
    end

    local dropGroupConfig = GachaDropConfig[resultGroupData.groupId]
    local dropHeroPool = {}
    if dropGroupConfig and  dropGroupConfig.hero and dropGroupConfig.weight then
        for i, dropHeroId in ipairs(dropGroupConfig.hero) do
            local weight = dropGroupConfig.weight[i]
            table.insert(dropHeroPool, {
                type = gachaType.hero,
                id = dropHeroId,
                weight = weight
            })
        end
    end

    if dropGroupConfig and  dropGroupConfig.furniture and dropGroupConfig.furnitureWeight then
        for i, dropid in ipairs(dropGroupConfig.furniture) do
            local weight = dropGroupConfig.furnitureWeight[i]
            table.insert(dropHeroPool, {
                type = gachaType.furniture,
                id = dropid,
                weight = weight
            })
        end
    end

    local result = util.randomByWeight(dropHeroPool, "weight")

    return result
end

local function getDropData(config, gachaCount, data)
    -- local logRuleType
    if #config.firstDropGroup > 0 and gachaCount == config.firstDropNum  then
        -- logRuleType = "新手保底掉落"
        return config.firstDropGroup, config.firstDropWeight,ruleType.newbie
    end
    -- 大小保底轮询
    if data.turn == lowType.big and config.bigNum > 0 and gachaCount % config.bigNum == 0 then
        -- logRuleType = "大保底"
        return config.bigDropGroup, config.bigDropWeight,ruleType.big
    elseif data.turn == lowType.small and config.middleNum > 0 and (gachaCount % config.middleNum == 0) then
        -- logRuleType = "小保底"
        return config.middleDropGroup, config.middleDropWeight,ruleType.small
    end

    if config.smallNum > 0 and gachaCount % config.smallNum == 0 then
        -- logRuleType = "x抽保底"
        return config.smallDropGroup, config.smallDropWeight,ruleType.xpump
    end
    -- logRuleType = "普通掉落"
    return config.oneDropGroup, config.oneDropWeight, ruleType.comm
end

local function ReqStartGacha(player, pid, proto)
    local id = proto.id
    local isOneTime = proto.isOneTime
    local config = GachaConfig[id]
    if not config then
        print("gacha config not find id", pid, id)
        return
    end

    -- local startTime = config.extendStartTime
    -- local endTime = config.endTime
    -- if next(startTime) ~= nil and next(endTime) ~= nil then
    --     local curTime = gTools:getNowTime()
    --     local st = gTools:getNowTimeByDate(startTime[1], startTime[2], startTime[3], startTime[4], startTime[5], startTime[6])
    --     local et = gTools:getNowTimeByDate(endTime[1], endTime[2], endTime[3], endTime[4], endTime[5], endTime[6])

    --     if curTime < st or curTime >= et then
    --         print("ReqStartGacha no open", pid)
    --         return  
    --     end
    -- end

    local lv = player:getLevel()
    if lv < config.openLevel then
        print("ReqStartGacha no open", pid)
        return
    end

    -- 连抽正常累计次数，连抽就是连续的的单抽，首连抽的最后一次触发首连抽掉落组，

    local cfgType = config.type
    local fixType = cardPoolType.limited
    local data = getDataByid(player, cfgType)
    if cardPoolType.newbie == cfgType and data.count >= config.firstDropNum then
        print("first drop num upper limit", pid, data.count)
        return
    end

    local totalCnt = getGachaCount(config, isOneTime)
    if config.cost then
        local needCost = config.cost[2] * totalCnt
        local cost = {{
            type = define.itemType.item,
            id = config.cost[1],
            count = needCost
        }}
        if not bagsystem.checkAndCostItem(player, cost) then
            return
        end
    end

    local items = {}
    local awards = {}
    local dropStringList = {}
    local totalGachaCount = totalCnt
    if (data.totalCnt or 0) <= 0 and (config.firstDrop or 0) > 0 then
        local heroId = config.firstDrop
        local heroType = gachaType.hero
        -- 首次必出
        totalGachaCount = totalCnt - 1
        data.count  = 1
        table.insert(awards, {
            id = heroId,
            count = 1,
            type = define.itemType.hero
        })
        table.insert(dropStringList, {
            type = heroType,
            id = heroId,
            count = 0
        })
        
        if not items[heroType] then
            items[heroType] = {}
        end
        items[heroType][heroId] = 1
    end

    for k, v in pairs(config.retItemId) do
        if v[1] and v[2] and v[3] then
            table.insert(awards, {
                type = v[1],
                id = v[2],
                count = v[3] * totalCnt
            })
        end
    end

    local gachaCount = data.count
    local logRuleType
    local dropHeroList = {}
    local isClear = false
    local cnt = 0
    local heroId = nil
    for i = 1, totalGachaCount do
        gachaCount = gachaCount + 1
        cnt = cnt + 1
        local isReset = false
        local dropGroup, dropWeight, logRuleType = getDropData(config, gachaCount, data)
        local resultDropHeroData = randDropPool(config, gachaCount, dropGroup, dropWeight)
        if logRuleType == ruleType.big or logRuleType == ruleType.small then
            isReset = true
        else
            if resultDropHeroData.type == gachaType.hero and resultDropHeroData.id > 0 then
                local hConfig = heroConfig[resultDropHeroData.id]
                if hConfig and hConfig.quality == 5 then
                    isReset = true
                    heroId = resultDropHeroData.id
                end
            end
        end

        if isReset then
            if cfgType == fixType then
                if data.turn == lowType.big then
                    data.turn = lowType.small
                    dropGroup = config.bigDropGroup
                    dropWeight = config.bigDropWeight
                elseif data.turn == lowType.small then
                    data.turn = lowType.big
                    dropGroup = config.middleDropGroup
                    dropWeight = config.middleDropWeight
                end
            end

            if cardPoolType.newbie ~= cfgType then
                isClear = true
                clearDataByid(player, cfgType)
                gachaCount = 0
                cnt = 0  
            end

            if totalGachaCount == 1 and heroId then
                dropHeroList = {{id=heroId,type=gachaType.hero,count=1}}
                break
            else
                if dropGroup and dropWeight and #dropGroup > 0 and #dropWeight > 0 then
                    resultDropHeroData = randDropPool(config, gachaCount, dropGroup, dropWeight)
                end
            end
        end
                
        table.insert(dropHeroList, resultDropHeroData)

        if cfgType == fixType and isReset == false and totalGachaCount == 1 then
            if dropHeroList[1].type == gachaType.hero then
               local conf = GachaDropConfig[config.bigDropGroup]
               if conf then
                    local id = conf.hero[1]
                    if id ~= dropHeroList[1].id then
                        dropHeroList[1].id = id
                        data.turn = lowType.small
                        data.count = 0
                    end
               end
            end
        end
    end

    if not isClear then
        addCount(player, cfgType, cnt)
    end

    if totalGachaCount == 10 and heroId then
        local forceFlag = false
        for k, v in pairs(dropHeroList) do
            if v.id == heroId then
                forceFlag = true
                break
            end
        end
        if forceFlag == false then
            dropHeroList[#dropHeroList] = {id=heroId,type=1,count=1}
        end
    end

    
    local heroType = gachaType.hero
    local furnType = gachaType.furniture
    local itemHeroType = define.itemType.hero
    local itemFurnType = define.itemType.furniture

    for i, v in pairs(dropHeroList) do
        local count = 0
        local id = v.id
        local type = v.type
        
        if not items[type] then
            items[type] = {}
        end

        if type == heroType then
            if herosystem.checkHasHero(player, id) or (items[type][id] or 0) >= 1 then
                count = 1
            end
            
            table.insert(awards, {
                id = v.id,
                count = 1,
                type = itemHeroType
            })
            items[type][id] = 1
        elseif type == furnType then
            if not furnituresystem.checkIsRepeatableHas(player, id) or (items[type][id] or 0) >= 1 then
                count = 1
            end

            table.insert(awards, {
                id = id,
                count = 1,
                type = itemFurnType
            })

            if not furnituresystem.isRepeatableHas(id) then
                items[type][id] = 1
            end
        end
        
        table.insert(dropStringList, {
            type = type,
            id = id,
            count = count
        })
    end

    sendGachaData(player, pid, dropStringList, cfgType)

    data.totalCnt = (data.totalCnt or 0) + totalCnt
    saveData(player)
    if awards and #awards > 0 then
        bagsystem.addItems(player, awards, define.rewardTypeDefine.recruit)
    end
    


    tasksystem.updateProcess(player, pid, define.taskType.recruit, {totalCnt}, define.taskValType.add)
end

local function ReqGacha(player, pid, proto)
    local res = {
        gachaData = {}
    }
    for k, v in pairs(GachaConfig) do
        table.insert(res.gachaData, writepackage(player, v.type))
    end

    net.sendMsg2Client(player, ProtoDef.ResGacha.name, res)
end

local function sendGacheAwardsData(player,type,code,item)
    local res = {}
    res.gachaData = writepackage(player, type)
    res.code = code
    res.award = item or {}
    net.sendMsg2Client(player, ProtoDef.ResGacheAwards.name, res)

end

local function ReqGacheAwards(player, pid, proto)

    local heroId,type = proto.heroId,proto.type
    local data = getDataByid(player, type)
    if not data or  data.heroid < 0 then
        print("ReqGacheAwards hero error  ,", pid, type, data.heroid)
        sendGacheAwardsData(player, type,msgCode.result.null)
        return
    end
    local config
    for k, v in pairs(GachaConfig) do
        if v.type == type then
            config = v
            break
        end
    end
    
    if not config then
        print("ReqGacheAwards GachaConfig not find ,", pid, type)
        sendGacheAwardsData(player,type, msgCode.result.null)
        return
    end
    if data.totalCnt < config.gachaMyselfNum then
        print("ReqGacheAwards total cnt not enough  ,", pid, type, data.totalCnt)
        sendGacheAwardsData(player,type, msgCode.result.cnt)
        return
    end

    local hCfg = heroConfig[heroId]
    if not hCfg then
        print("ReqGacheAwards total cnt not enough,", pid, type, data.totalCnt)
        sendGacheAwardsData(player,type, msgCode.result.null)
        return
    end

    local award = {type = define.itemType.hero, id = heroId,count = 1}
    local tip = {type = gachaType.hero, id = heroId,count = 0}
    if herosystem.checkHasHero(player, heroId)then
        award = {type = define.itemType.item, id = hCfg.starUpMaterial,count = 1}
        tip.count = 1
    end

    bagsystem.addItems(player, {award}) 
    data.heroid = -1
    saveData(player)
    sendGacheAwardsData(player,type, msgCode.result.success,tip)
end

local function setgachadata(player, pid, args)
    pid = 3518438940558369355
    player = gPlayerMgr:getPlayerById(pid)
    local data = getData(player)
    data["2"].count = 69
    saveData(player)
end



gm.reg("setgachadata", setgachadata)



net.regMessage(ProtoDef.ReqStartGacha.id, ReqStartGacha, net.messType.gate)
net.regMessage(ProtoDef.ReqGacheAwards.id, ReqGacheAwards, net.messType.gate)
net.regMessage(ProtoDef.ReqGacha.id, ReqGacha, net.messType.gate)


