



local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"
local playermoduledata = require "common.playermoduledata"
local dropsystem = require "logic.system.dropsystem"
local bagsystem = require "logic.system.bagsystem"



local systemConfig = require "logic.config.system"
local towerConfig = require "logic.config.towerConfig"
local towerSkillConfig = require "logic.config.towerSkillConfig"
local towerSkillOptionConfig = require "logic.config.towerSkillOptionConfig"

local dropsystem = require "logic.system.dropsystem"



local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.tower)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.tower)
end


local function getHeroData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.hero)
end

-- 爬塔事件类型定义
local towerEventTypeDef =
{
    fight = 1, -- 战斗
    fightBuff = 2, -- 战斗buff
    store = 3, -- 商店
    change1 = 4, -- 抉择(以物换物)
    xiuzheng = 5, -- 修整(复活/恢复生命/添加新英雄)
}

local heroOptDef =
{
    addHp  = 1, -- 恢复生命
    revert = 2, -- 复活
    addHero = 3, -- 添加英雄
}

-- 付费奖励解锁状态
local costRdStateDef =
{
    lock = 0, -- 未解锁
    unlock = 1, -- 已经解锁
}

local fightEndVal = 2 -- 战斗结束状态

local wheelMaxIdx = 2

local function getDiffConfig(diff)
    return towerConfig[diff]
end

local function getConfig(diff, layer, idx)
    return towerConfig[diff]["ground"][layer][idx]
end

local function getLayerConfig(diff, layer)
    return towerConfig[diff]["ground"][layer]
end


local function randBuff(pid, chooseedBuff, buffGroupConf)
    local ret = {}
    for _, buffGroupId in pairs(buffGroupConf) do
        local conf = towerSkillConfig[buffGroupId]
        if conf then
            local buffStore = conf.buffStore[buffGroupId]
            local maxWeight = 0
            local tab = {}

            for k, poll in ipairs(buffStore) do
                local buffId = poll.id
                if not tools.isInArr(chooseedBuff, buffId) then
                    maxWeight = maxWeight + poll.weight
                    table.insert(tab, {poll.id, maxWeight})
                end
            end

            if maxWeight > 0 then
                local randVal = math.random(1, maxWeight)
                for k, v in ipairs(tab) do
                    if randVal <= v[2] then
                        local buffId = v[1]
                        table.insert(chooseedBuff, buffId)
                        table.insert(ret, buffId)
                        break
                    end
                end
            else
                print("randBuff no enough buff poll", pid)
            end
        end
    end


    return ret
end

local function randLayer(player, pid, datas, layer, conf)
    local tab = {}
    local maxWeight = 0
    for k, v in ipairs(conf) do
        maxWeight = maxWeight + v.weight
        table.insert(tab, maxWeight)
    end

    local rval = math.random(1, maxWeight)
    local idx = nil
    for k, v in ipairs(tab) do
        if rval <= v then
            idx = k
            break
        end
    end

    --idx = 1
    local cfg = conf[idx]
    local eventType = cfg.eventType

    datas.eidx = idx
    datas.layer = layer

    local conf = nil
    if eventType == towerEventTypeDef.fightBuff then
        conf = cfg.selectBuffReward or {} 
    elseif eventType == towerEventTypeDef.store then
        conf = cfg.shopBuy or {} 
    end

    if conf then
        local chooseedBuff = tools.clone(datas.chooseedBuff)
        local ret = randBuff(pid, chooseedBuff, conf)
        datas.chooseBuff = tools.clone(ret)
    end


end

local function addHero(player, pid, heroId, heroData)
    local cloneHeroData = tools.clone(heroData)


    local tmp = {}
    local equipInfo = {}
    for eid, _ in pairs(heroData.equipList or {}) do
        local equip = bagsystem.getItemInfo(player, pid, eid)
        if not equip then
            print("addHero no equip", pid, heroId)
        else
            local equipMsg = bagsystem.packOneItemInfo(eid, equip)
            table.insert(equipInfo, equipMsg)
        end
    end
    
    tmp.hp = 10000
    tmp.hero = cloneHeroData
    tmp.equip = equipInfo

    return tmp
end

local function addHisLayer(datas, diff, layer)
    local sdiff = tostring(diff)
    local layerRdData = datas.layerRdData
    layerRdData[sdiff] = layerRdData[sdiff] or {}
    local layerData = layerRdData[sdiff]
    local hisLayer = layerData.layer or 0
    if layer > hisLayer then
        layerData.layer = layer
    end
end

local function isPass(pass)
    pass = pass or 0
    return pass > 0
end

local function addScore(datas, id, count)
    if id == define.currencyType.towerScore then
        datas.score = datas.score + count
        return true
    end

    return false
end

local function getEventTypeRd(datas, cfg)
    local rd = dropsystem.getDropItemList(cfg)
    local rds = {}
    for k, v in pairs(rd) do
        local ok = addScore(datas, v.id, v.count)
        if not ok then
            table.insert(rds, v)
        end
    end

    return rds
end


local function calcRealScore(player, datas, diff)
    local score = datas.score or 0
    
    local retRd = tools.clone(datas.firstReward or {})
    datas.firstReward = nil
    if score > 0 then
        local conf = getDiffConfig(diff)
        if conf then
            local rds = {}

            local passPoint = conf.passPoint
            if datas.pass ~= fightEndVal then
                passPoint = 0
            end
            
            score = math.floor(score * conf.passParameter / 10000 + passPoint)
            datas.score = score

            tools.mergeRewardArr(rds, retRd)
            table.insert(rds, {id=define.currencyType.towerScore,count=score,type=define.itemType.currency})
            

            bagsystem.addItems(player, rds, define.rewardTypeDefine.notshow)
        end
    end

    return score, retRd

end

local function enterNextLayer(player, pid, datas, diff, layer)
    local nextLayer = layer + 1
    local layerCfg = getLayerConfig(diff, nextLayer)
    if layerCfg then
        randLayer(player, pid, datas, nextLayer, layerCfg)

        local msgs = {}
        msgs.layer = nextLayer
        msgs.idx = datas.eidx
        msgs.chooseBuff = datas.chooseBuff or {}
        msgs.score = datas.score or 0


        net.sendMsg2Client(player, ProtoDef.NotifyEnterNextLayer.name, msgs)


    else
        datas.diffs = datas.diffs or {}
        local diffs = datas.diffs

        if not tools.isInArr(diffs, diff) then
            table.insert(diffs, diff)
            local conf = getDiffConfig(diff)
            if conf then
                datas.firstReward = dropsystem.getDropItemList(conf.firstReward)
            end
        end

        datas.pass = fightEndVal
    

        net.sendMsg2Client(player, ProtoDef.NotifyEnterNextLayer.name, {pass=fightEndVal})
    end
end


local function packOneHeroData(heroId, heroData)
    local msg = {}
    msg.hp = heroData.hp
    msg.hero = _G.gLuaFuncPackOneHeroInfo(heroId, heroData.hero or {})
    msg.equip = heroData.equip

    return msg
end

local function packHeroData(data)
   local msgs = {}

    for heroId, v in pairs(data) do
        local msg = packOneHeroData(heroId, v)
        table.insert(msgs, msg)
    end

    return msgs
end




local function packTowerInfo(datas, usePosInfo)
    usePosInfo = usePosInfo or false
    local msgs = {}
    if usePosInfo == true then
        msgs.posInfo = datas.posInfo or {}
        return msgs
    end

    msgs.diff = datas.diff or 0
    msgs.layer = datas.layer or 0
    msgs.idx = datas.eidx or 0
    msgs.posInfo = datas.posInfo or {}
    msgs.heroData = packHeroData(datas.hero or {})
    msgs.chooseBuff = datas.chooseBuff or {}
    msgs.chooseedBuff = datas.chooseedBuff
    msgs.score = datas.score or 0
    msgs.pass = datas.pass or 0

    return msgs
end

local function packLayerRdData(layerRdData)
    local msgs = {}
    for k, v in pairs(layerRdData) do
        local msg = {}
        msg.diff = tonumber(k)
        msg.idxs = v.idxs or {}
        msg.state = v.state or costRdStateDef.lock
        msg.layer = v.layer or 0

        table.insert(msgs, msg)
    end

    return msgs
end



local function ReqTowerAllInfo(player, pid, proto)
    -- if not _G.gluaFuncFuntionIsOpen(player, define.functionOpen.tower) then
    --     print("ReqTowerAllInfo no open", pid)
    --     return
    -- end

    local datas = getData(player)
    if not datas then
        print("ReqTowerAllInfo no datas", pid)
        return
    end

    --tools.ss(datas)


    local msgs = {data = {}}
    local data = msgs.data
    data.tower = packTowerInfo(datas)
    data.endTime = datas.endTime
    data.diffs = datas.diffs or {}
    data.idx = datas.idx
    data.freeIdx = datas.freeIdx or {}
    data.costIdx = datas.costIdx or {}
    data.state = datas.state or costRdStateDef.lock
    data.layerRdData = packLayerRdData(datas.layerRdData or {})


    --tools.ss(msgs)
    net.sendMsg2Client(player, ProtoDef.ResTowerAllInfo.name, msgs)
end

local function ReqChooseDiff(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqChooseDiff no datas", pid)
        return
    end

    local diff = proto.diff
    local type = proto.type
    if type == 1 and datas.diff ~= diff then
        print("ReqChooseDiff choose err", pid)
        return
    end

    if type == 0 and diff > 1 then
        local preDiff = diff - 1
        if not tools.isInArr(datas.diffs, preDiff) then
            print("ReqChooseDiff no pass", pid)
            return
        end

    end

    local conf = getLayerConfig(diff, 1)
    if not conf then
        print("ReqChooseDiff no conf", pid, diff)
        return
    end

    local heroData = getHeroData(player)
    if not heroData then
        print("ReqChooseDiff no heroData", pid)
        return
    end

    local heroList = heroData.heroList
    if not heroList then
        print("ReqChooseDiff no heroList", pid)
        return
    end

    local posInfo = proto.posInfo
    local type = proto.type
    local hero = {}
    local ok = false
    local myHero = datas.hero or {}
    local pos = {}


    for _, heroId in pairs(posInfo) do
        table.insert(pos, heroId)
        if heroId > 0 then
            ok = true
            local sid = tostring(heroId)
            if type == 0 then
                local tmp = {}
                local heroData = heroList[sid]
                if not heroData then
                    print("ReqChooseDiff no hero1", pid, heroId)
                    return
                end
    
                hero[sid] = addHero(player, pid, heroId, heroData)
            else
                local heroData = myHero[sid]
                if not heroData then
                    print("ReqChooseDiff no hero2", pid, heroId)
                    return
                end

                if heroData.hp <= 0 then
                    print("ReqChooseDiff zero hp", pid, heroId)
                    return
                end
            end

        end
    end

    if ok == false then
        print("ReqChooseDiff empty list", pid)
        return
    end

    datas.pass = nil

    local usePos = true
    if type == 0 then
        randLayer(player, pid, datas, 1, conf)
        datas.hero = hero
        usePos = false
    end
    
    datas.diff = diff
    datas.posInfo = pos


    saveData(player)

    local msgs = {}
    msgs.type = type

    msgs.data = packTowerInfo(datas, usePos)

    net.sendMsg2Client(player, ProtoDef.ResChooseDiff.name, msgs)
end


local function ReqPlayerChoose(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqPlayerChoose no datas", pid)
        return
    end

    if isPass(datas.pass) then
        print("ReqPlayerChoose is pass", pid)
        return
    end

    local diff = datas.diff
    local layer = datas.layer
    local idx = datas.eidx
    local cfg = getConfig(diff, layer, idx)

    if not cfg then
        print("ReqPlayerChoose no cfg", pid, diff, layer, idx)
        return
    end

    local index = proto.idx
    local clayer = proto.layer
    if clayer ~= layer then
        print("ReqPlayerChoose no match layer", pid, diff, layer, clayer, idx)
        return
    end

    local notice = bagsystem.makeNotice()
    local preScore = datas.score or 0

    local eventType = cfg.eventType
    if eventType == towerEventTypeDef.fight or 
    eventType == towerEventTypeDef.fightBuff or 
    eventType == towerEventTypeDef.store then
        if eventType == towerEventTypeDef.store then
            if index ~= -1 then
                local chooseBuff = datas.chooseBuff
                if not chooseBuff then
                    print("ReqPlayerChoose no chooseBuff", pid, diff, layer, idx)
                    return
                end
        
                local val = chooseBuff[index]
                if not chooseBuff then
                    print("ReqPlayerChoose no val", pid, diff, layer, idx)
                    return
                end

                local costCfg = towerSkillOptionConfig[val]
                if not costCfg then
                    print("ReqPlayerChoose no costCfg", pid, diff, layer, idx)
                    return
                end

                local shopBuffCost = costCfg.shopBuffCost

                if not bagsystem.checkAndCostItem(player, {{id=shopBuffCost[2],count=shopBuffCost[3],type=shopBuffCost[1]}}) then
                    return
                end
        
                datas.chooseBuff = nil
                table.insert(datas.chooseedBuff, val)
        
                if next(cfg.eventReward) then
                    local rd = getEventTypeRd(datas, cfg.eventReward)

                    if next(rd) then
                        notice.param1 = (datas.score or 0) - preScore
                        tools.mergeSameIdReward(datas.rds, rd)
                        bagsystem.addItems(player, rd, define.rewardTypeDefine.towerRd, notice)
                    end
                end



            end
        else
            local chooseBuff = datas.chooseBuff
            if not chooseBuff then
                print("ReqPlayerChoose no chooseBuff", pid, diff, layer, idx)
                return
            end
    
            local val = chooseBuff[index]
            if not chooseBuff then
                print("ReqPlayerChoose no val", pid, diff, layer, idx)
                return
            end
    
            datas.chooseBuff = nil
            table.insert(datas.chooseedBuff, val)
    
            local rd = getEventTypeRd(datas, cfg.eventReward)
            if next(rd) then
                notice.param1 = (datas.score or 0) - preScore

                tools.mergeSameIdReward(datas.rds, rd)
                bagsystem.addItems(player, rd, define.rewardTypeDefine.towerRd, notice)
            end
        end


    elseif eventType == towerEventTypeDef.change1 then
        local conf = cfg.selectCost[index]
        if not conf then
            print("ReqPlayerChoose no conf", pid, diff, layer, idx)
            return
        end

        local rdCfg = cfg.selectReward[index]
        if not rdCfg then
            print("ReqPlayerChoose no rdCfg", pid, diff, layer, idx)
            return
        end

        if not bagsystem.checkAndCostItem(player, {{id=conf[2],count=conf[3],type=conf[1]}}) then
            return
        end

        local rd = getEventTypeRd(datas, cfg.eventReward)
        tools.mergeSameIdReward(datas.rds, rd)

        
        local id = rdCfg[2]
        local count = rdCfg[3]
        local type = rdCfg[1]
        
        local sid = tostring(id)
        datas.rds[sid] = (datas.rds[sid] or 0) + count

        if not addScore(datas, id, count) then
            table.insert(rd, {id=id,type=type,count=count})
        end
    
        notice.param1 = (datas.score or 0) - preScore
        bagsystem.addItems(player, rd, define.rewardTypeDefine.towerRd, notice)

    else
        print("ReqPlayerChoose no support type", pid, diff, layer, idx)
        return
    end



    net.sendMsg2Client(player, ProtoDef.ResPlayerChoose.name, {idx = index})

    enterNextLayer(player, pid, datas, diff, layer)

    saveData(player)

end

local function ReqFightTowerCheck(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqFightTowerCheck no datas", pid)
        return
    end

    if isPass(datas.pass) then
        print("ReqFightTowerCheck is pass", pid)
        return
    end

    local diff = datas.diff
    local layer = datas.layer
    local idx = datas.eidx
    local cfg = getConfig(diff, layer, idx)
    
    if not cfg then
        print("ReqFightTowerCheck no cfg", pid, diff, layer, idx)
        return
    end

    if cfg.eventType ~= towerEventTypeDef.fight then
        print("ReqFightTowerCheck no match type", pid, diff, layer, idx)
        return
    end

    net.sendMsg2Client(player, ProtoDef.ResFightTowerCheck.name, {})
end

local function ReqTowerFightEnd(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqTowerFightEnd no datas", pid)
        return
    end

    if isPass(datas.pass) then
        print("ReqTowerFightEnd is pass", pid)
        return
    end

    local diff = datas.diff
    local layer = datas.layer
    local idx = datas.eidx
    local diffConf = getDiffConfig(diff)
    if not diffConf then
        print("ReqTowerFightEnd no diffConf", pid, diff, layer)
        return
    end

    local layerCfg = diffConf.ground
    local cfg = layerCfg[layer][idx]
    if not cfg then
        print("ReqTowerFightEnd no cfg", pid, diff, layer, idx)
        return
    end

    local leftHpData = proto.data
    local myHero = datas.hero
    local posInfo = datas.posInfo or {}
    for k, v in pairs(leftHpData) do
        local heroId = v.heroId
        local sid = tostring(heroId)
        local info = myHero[sid]
        if not info then
            print("ReqTowerFightEnd no info", pid, diff, layer, idx, sid)
            return
        end

        local leftHp = v.hp
        info.hp = leftHp

        for index, hid in pairs(posInfo) do
            if heroId == hid and leftHp <= 0 then
                posInfo[index] = 0
            end
        end
    end



    local res = proto.res
    local notice = bagsystem.makeNotice()

    if res == 1 then
        local preScore = datas.score or 0

        local rd = getEventTypeRd(datas, cfg.eventReward)
        tools.mergeSameIdReward(datas.rds, rd)

        local fightReward = cfg.fightReward
        for k, v in pairs(fightReward) do
            local id = v[2]
            local count = v[3]
            local type = v[1]
            
            local sid = tostring(id)
            datas.rds[sid] = (datas.rds[sid] or 0) + count

            if not addScore(datas, id, count) then
                table.insert(rd, {id=id,type=type,count=count})
            end
        end


        notice.param1 = (datas.score or 0) - preScore
        bagsystem.addItems(player, rd, define.rewardTypeDefine.fightEnd, notice)

        local fightBuffReward = cfg.fightBuffReward
        local chooseedBuff = tools.clone(datas.chooseedBuff)

        local ret = randBuff(pid, chooseedBuff, fightBuffReward)

        local msgs = {res = res}

        msgs.chooseBuff = tools.clone(ret)
        datas.chooseBuff = tools.clone(ret)


        net.sendMsg2Client(player, ProtoDef.ResTowerFightEnd.name, msgs)

        local maxLayer = #layerCfg
        if layer >= maxLayer then

            enterNextLayer(player, pid, datas, diff, layer)
        end



    else
        local tipMsg = {}
        tipMsg.rdType = define.rewardTypeDefine.fightEnd
        net.sendMsg2Client(player, ProtoDef.NotifyClientRewardTips.name, tipMsg)
    end

    saveData(player)
end

local function ReqStopTower(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqStopTower no datas", pid)
        return
    end

    local diff = datas.diff or 0
    if diff <= 0 then
        print("ReqStopTower no diff", pid)
        return
    end

    local delId = define.currencyType.towerCurrency
    local count = bagsystem.getCurrencyNumById(player, delId)
    if count > 0 then
        bagsystem.costItems(player, {{id=delId,count=count,type=define.itemType.currency}})
    end


    addHisLayer(datas, diff, datas.layer)

    local score, retRd = calcRealScore(player, datas, datas.diff, true)

    local endTime = datas.endTime
    local layerRdData = tools.clone(datas.layerRdData or {})
    local idx = datas.idx
    local state = datas.state
    local freeIdx = tools.clone(datas.freeIdx or {})
    local costIdx = tools.clone(datas.costIdx or {})
    local diffs = tools.clone(datas.diffs or {})
    local pass = datas.pass or 0
    local rds = tools.clone(datas.rds or {})
    local items = {}

    for k, v in pairs(datas.rds or {}) do
        local itemId = tonumber(k)
        local itemType = define.itemType.item
        if itemId >= define.currencyType.gold and itemId <= define.currencyType.max then
            itemType = define.itemType.currency
        end

        table.insert(items, {id=itemId, count=v, type = itemType})
    end

    for k, v in pairs(retRd) do
        table.insert(items, 1, v)
    end



    tools.cleanTableData(datas)

    datas.endTime = endTime
    datas.idx = idx
    datas.layerRdData = layerRdData
    datas.chooseedBuff = {}
    datas.freeIdx = freeIdx
    datas.costIdx = costIdx
    datas.state = state
    datas.diffs = diffs
    datas.score = 0
    datas.rds = {}
    datas.calc = nil
    datas.pass = pass



    saveData(player)

    local msgs = {score = score, items = items, pass = pass}
    net.sendMsg2Client(player, ProtoDef.ResStopTower.name, msgs)

end

local function ReqRefTowerShop(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqRefTowerShop no datas", pid)
        return
    end

    if isPass(datas.pass) then
        print("ReqRefTowerShop is pass", pid)
        return
    end

    local diff = datas.diff
    local layer = datas.layer
    local idx = datas.eidx
    local cfg = getConfig(diff, layer, idx)
    if not cfg then
        print("ReqRefTowerShop no cfg", pid, diff, layer, idx)
        return
    end

    if cfg.eventType ~= towerEventTypeDef.store then
        print("ReqRefTowerShop no match type", pid, diff, layer, idx)
        return
    end

    local towerShopCost = systemConfig[0].towerShopCost
    if not bagsystem.checkAndCostItem(player, {{id=towerShopCost[2],count=towerShopCost[3],type=towerShopCost[1]}}) then
        return
    end

    local shopBuy = cfg.shopBuy or {}
    local chooseedBuff = tools.clone(datas.chooseedBuff)
    local ret = randBuff(pid, chooseedBuff, shopBuy)
    datas.chooseBuff = tools.clone(ret)


    local msgs = {}
    msgs.goods = ret

    saveData(player)

    net.sendMsg2Client(player, ProtoDef.ResRefTowerShop.name, msgs)
end

local function ReqTowerHeroOpt(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqTowerHeroOpt no datas", pid)
        return
    end

    if isPass(datas.pass) then
        print("ReqTowerHeroOpt is pass", pid)
        return
    end

    local diff = datas.diff
    local layer = datas.layer
    local idx = datas.eidx
    local cfg = getConfig(diff, layer, idx)
    if not cfg then
        print("ReqTowerHeroOpt no cfg", pid, diff, layer, idx)
        return
    end

    local clayer = proto.layer
    if clayer ~= layer then
        print("ReqTowerHeroOpt no match layer", pid, diff, layer, clayer, idx)
        return
    end


    if cfg.eventType ~= towerEventTypeDef.xiuzheng then
        print("ReqTowerHeroOpt no match type", pid, diff, layer, idx)
        return
    end

    local opt = proto.opt
    local heroId = proto.heroId
    local sid = tostring(heroId)
    local hero = datas.hero

    local msgs = {opt = opt, heroId = heroId}

    if opt == heroOptDef.addHp then
        for k, v in pairs(hero) do
            if v.hp > 0 then
                v.hp = 10000
            end
            
        end

    elseif opt == heroOptDef.revert then
        local info = hero[sid]
        if not info then
            print("ReqTowerHeroOpt no info", pid, diff, layer, idx, sid)
            return
        end

        if info.hp > 0 then
            print("ReqTowerHeroOpt hp>0", pid, diff, layer, idx, sid)
            return
        end
    
        info.hp = systemConfig[0].towerPointRecover
    elseif opt == heroOptDef.addHero then
        local heros = getHeroData(player) or {}
        local heroList = heros.heroList or {}
        local heroData = heroList[sid]
        if not heroData then
            print("ReqTowerHeroOpt no info", pid, diff, layer, idx)
            return
        end

        if hero[sid] then
            print("ReqTowerHeroOpt have hero", pid, diff, layer, idx, sid)
            return
        end

        local newInfo = addHero(player, pid, heroId, heroData)
        hero[sid] = newInfo

        msgs.data = packOneHeroData(heroId, newInfo)
    else
        print("ReqTowerHeroOpt no match type", pid, diff, layer, idx)
        return
    end

    local rd = getEventTypeRd(datas, cfg.eventReward)
    tools.mergeSameIdReward(datas.rds, rd)
    
    bagsystem.addItems(player, rd)



    enterNextLayer(player, pid, datas, diff, layer)

    saveData(player)


    net.sendMsg2Client(player, ProtoDef.ResTowerHeroOpt.name, msgs)
end

local function getScoreRd(pid, score, rd, conf, idxList, nowList)
    for k, v in pairs(idxList) do
        if tools.isInArr(nowList, v) then
            print("ReqTowerScoreRd recved", pid, v)
            return
        end

        local cfg = conf[v]
        if not cfg then
            print("ReqTowerScoreRd no cfg", pid, v)
            return
        end

        if score < cfg[1] then
            print("ReqTowerScoreRd no enough score", pid, v, score)
            return
        end

        table.insert(rd, {id=cfg[3],type=cfg[2],count=cfg[4]})

        table.insert(nowList, v)
    end
end

local function ReqTowerScoreRd(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqTowerScoreRd no datas", pid)
        return
    end

    local idx = datas.idx
    local conf = systemConfig[0].towerPointReward1
    local conf1 = systemConfig[0].towerPointCostReward1
    if idx ~= 1 then
        conf = systemConfig[0].towerPointReward2
        conf1 = systemConfig[0].towerPointCostReward2
    end

    local score = bagsystem.getCurrencyNumById(player, define.currencyType.towerScore)
    local rd = {}

    datas.freeIdx = datas.freeIdx or {}
    local freeIdx = datas.freeIdx
    getScoreRd(pid, score, rd, conf, proto.freeIdxList, freeIdx)

    datas.costIdx = datas.costIdx or {}
    local costIdx = datas.costIdx

    getScoreRd(pid, score, rd, conf1, proto.costIdxList, costIdx)

    if next(rd) then
        saveData(player)
        bagsystem.addItems(player, rd)

        net.sendMsg2Client(player, ProtoDef.ResTowerScoreRd.name, proto)
    end






end

local function ReqUnlockCostRd(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqUnlockCostRd no datas", pid)
        return
    end

    -- local state = datas.state or costRdStateDef.lock
    -- if state == costRdStateDef.unlock then
    --     print("ReqUnlockCostRd unlock", pid)
    --     return
    -- end

    -- local cfg = systemConfig[0]
    -- local towerPointCost = cfg.towerPointCost
    -- local cost = {{id=towerPointCost}}
    -- if not bagsystem.checkAndCostItem(player, cost) then
    --     return
    -- end

    datas.state = costRdStateDef.unlock
    saveData(player)

    local msgs = {}
    net.sendMsg2Client(player, ProtoDef.ResUnlockCostRd.name, msgs)
end


local function ReqRecvLayerRd(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqRecvLayerRd no datas", pid)
        return
    end

    local diff = proto.diff
    local idxs = proto.idxs

    local conf = getDiffConfig(diff)
    if not conf then
        print("ReqRecvLayerRd no conf", pid, diff)
        return
    end

    local sdiff = tostring(diff)

    local layerRdData = datas.layerRdData
    local data = layerRdData[sdiff]
    if not data then
        print("ReqRecvLayerRd no data", pid, diff)
        return
    end

    local hisIdx = data.idxs or {}
    local hisLayer = data.layer or 0
    local floorRewardCondition = conf.floorRewardCondition
    local floorReward = conf.floorReward
    local dropList = {}

    for k, v in pairs(idxs) do
        local needLayer = floorRewardCondition[v]
        if not needLayer then
            print("ReqRecvLayerRd no needLayer", pid, diff, v)
            return
        end

        if tools.isInArr(hisIdx, v) then
            print("ReqRecvLayerRd recved", pid, diff, v)
            return
        end
        
        if needLayer > hisLayer then
            print("ReqRecvLayerRd no com", pid, diff, v)
            return
        end 

        local rd = floorReward[v]
        if not rd then
            print("ReqRecvLayerRd no rd", pid, diff, v)
            return
        end

        for _, dropId in pairs(rd) do
            table.insert(dropList, dropId)
        end

        table.insert(hisIdx, v)
    end

    data.idxs = hisIdx

    local rd = dropsystem.getDropItemList(dropList)

    bagsystem.addItems(player, rd)

    saveData(player)

    net.sendMsg2Client(player, ProtoDef.ResRecvLayerRd.name, proto)
end

local function ReqUnlockLayerRd(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqUnlockLayerRd no datas", pid)
        return
    end

    local diff = proto.diff
    local sdiff = tostring(diff)


    local layerRdData = datas.layerRdData
    local data = layerRdData[sdiff]
    if not data then
        print("ReqUnlockLayerRd no data", pid, diff)
        return
    end

    local state = data.state or costRdStateDef.lock
    if state == costRdStateDef.unlock then
        print("ReqUnlockLayerRd unlock", pid, diff)
        return
    end

    local conf = getDiffConfig(diff)
    if not conf then
        print("ReqUnlockLayerRd no conf", pid, diff)
        return
    end

    local floorRewardCost = conf.floorRewardCost
    if not bagsystem.checkAndCostItem(player, {{id=floorRewardCost[2],type=floorRewardCost[1],count=floorRewardCost[3]}}) then
        return
    end

    data.state = costRdStateDef.unlock

    saveData(player)

    net.sendMsg2Client(player, ProtoDef.ResUnlockLayerRd.name, {diff = diff})
end


local function calcEndTime(curTime)
    local curTime = gTools:getNowTime()
    local zeroTime = gTools:get0Time(curTime)
    local nowWeek = gTools:getDayOfWeek(curTime)

    local endTime = 0
    local refTime = zeroTime + 14400
    if nowWeek == 1 and curTime < refTime then
        endTime = refTime
    else
        endTime = zeroTime + 86400 * (7 - nowWeek + 1) + 14400
    end

    return endTime
end

local function InitTowerData(player)
    local datas = getData(player)
    local curTime = gTools:getNowTime()
    local endTime = calcEndTime(curTime)


    datas.endTime = endTime
    datas.chooseedBuff = {}
    datas.score = 0
    datas.layerRdData = {}
    datas.rds = {}
    datas.idx = 1

    saveData(player)
end

local function newDay(player, pid, curTime, isOnline)
    local datas = getData(player)
    if not datas then
        return
    end


    local msgs = {}

    local endTime = datas.endTime

    if endTime and curTime >= endTime then
        datas.state = nil
        datas.freeIdx = nil
        datas.costIdx = nil

        local endTime = calcEndTime(curTime)
        msgs.endTime = endTime
        datas.endTime = endTime

        local idx = datas.idx
        idx = idx + 1
        if idx > wheelMaxIdx then
            idx = 1
        end

        datas.idx = idx
        msgs.idx = datas.idx

        local id = define.currencyType.towerScore
        local count = bagsystem.getCurrencyNumById(player, id)
        if count > 0 then
            bagsystem.costItems(player, {{id=id,type=define.itemType.currency,count=count}})
        end
    end

    datas.layerRdData = {}


    saveData(player)

    if isOnline then
        net.sendMsg2Client(player, ProtoDef.NotifyNewDay.name, msgs)
    end
    
end

local function cleantowerdata(player, pid, args)
    local datas = getData(player)
    tools.cleanTableData(datas)
    local curTime = gTools:getNowTime()
    _G.gLuaFuncInitTowerData(player, datas, curTime)
    saveData(player)
end

local function showtowerdata(player, pid, args)
    ReqTowerAllInfo(player, pid)
end

local function choosetowerdata(player, pid, args)
    local diff = 1
    local posInfo = {}
    local type = 0

    ReqChooseDiff(player,pid,{diff=diff,posInfo=posInfo,type=0})
end

local function choosetowerbuff(player, pid, args)
    local idx = 1

    ReqPlayerChoose(player,pid,{idx=idx})
end

local function choosetowerstop(player, pid, args)
    local idx = 1

    ReqStopTower(player,pid)
end

local function choosetowerfightend(player, pid, args)
    local idx = 1

    ReqTowerFightEnd(player,pid,{res=1})
end

_G.gLuaFuncInitTowerData = InitTowerData

gm.reg("cleantowerdata", cleantowerdata)
gm.reg("showtowerdata", showtowerdata)
gm.reg("choosetowerdata", choosetowerdata)
gm.reg("choosetowerbuff", choosetowerbuff)
gm.reg("choosetowerstop", choosetowerstop)
gm.reg("choosetowerfightend", choosetowerfightend)
gm.reg("choosetowerfightend", choosetowerfightend)

event.reg(event.eventType.newDay, newDay)

net.regMessage(ProtoDef.ReqTowerAllInfo.id, ReqTowerAllInfo, net.messType.gate)
net.regMessage(ProtoDef.ReqChooseDiff.id, ReqChooseDiff, net.messType.gate)
net.regMessage(ProtoDef.ReqPlayerChoose.id, ReqPlayerChoose, net.messType.gate)
net.regMessage(ProtoDef.ReqFightTowerCheck.id, ReqFightTowerCheck, net.messType.gate)
net.regMessage(ProtoDef.ReqTowerFightEnd.id, ReqTowerFightEnd, net.messType.gate)
net.regMessage(ProtoDef.ReqStopTower.id, ReqStopTower, net.messType.gate)
net.regMessage(ProtoDef.ReqRefTowerShop.id, ReqRefTowerShop, net.messType.gate)
net.regMessage(ProtoDef.ReqTowerHeroOpt.id, ReqTowerHeroOpt, net.messType.gate)
net.regMessage(ProtoDef.ReqTowerScoreRd.id, ReqTowerScoreRd, net.messType.gate)
net.regMessage(ProtoDef.ReqUnlockCostRd.id, ReqUnlockCostRd, net.messType.gate)
net.regMessage(ProtoDef.ReqRecvLayerRd.id, ReqRecvLayerRd, net.messType.gate)
net.regMessage(ProtoDef.ReqUnlockLayerRd.id, ReqUnlockLayerRd, net.messType.gate)







