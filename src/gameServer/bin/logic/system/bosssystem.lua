




local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"
local playermoduledata = require "common.playermoduledata"
local dropsystem = require "logic.system.dropsystem"
local bagsystem = require "logic.system.bagsystem"
local heroConfig = require "logic.config.hero"

local equipConfig = require "logic.config.equip"
local systemConfig = require "logic.config.system"
local system0Config = systemConfig[0]
local manageGameplayConfig = require "logic.config.manageGameplayConfig"


local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.boss)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.boss)
end

local function getHeroData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.hero)
end

local function getEquipHistoryData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.equipHistory)
end

local equipMinStep = 1 -- 装备最小阶级
local equipMaxStep = 8 -- 装备最大阶级
-- 英雄有装备且阶级是boss喜爱物加成固定值
local harmFixedVal = 2
-- 英雄没有装备图纸最高阶数量
local maxForlumaStepCnt = 10
--英雄没有装备图纸阶级范围,百分比
local bossRangeStep = 
{
    [-2]=5,
    [-1]=10,
    [0]=25,
    [1]=10,
    [2]=5,
}

local function getCheckpointCfg(id, idx)
    return manageGameplayConfig[id]["chapter"][idx][1]
end

local function getChapterMinIdx(chapter)
    local minIdx = 0
    for k, v in pairs(chapter) do
        if minIdx == 0 then
            minIdx = k
        else
            if k < minIdx then
                minIdx = k
            end
        end
    end

    return minIdx
end

local function packBossCheckpointInfo(checkpoint)
    local msgs = {}

    for k, v in pairs(checkpoint) do
        local msg = {}
        msg.idx = tonumber(k)
        msg.maxHarm = v.maxHarm or 0

        table.insert(msgs, msg)
    end

    return msgs
end

local function packBossInfo(bossData)
    local msgs = {}
    for k, v in pairs(bossData) do
        local msg = {}
        msg.id = tonumber(k)
        msg.data = packBossCheckpointInfo(v)

        table.insert(msgs, msg)
    end

    return msgs
end

local function packBossTeam(teamData)
    local msgs = {}
    for k, v in pairs(teamData) do
        local msg = {}
        msg.id = tonumber(k)
        msg.heroIds = v

        table.insert(msgs, msg)
    end

    return msgs
end

local function ReqBossInfo(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqBossInfo no datas", pid)
        return
    end

    local msgs = {}
    msgs.endTime = datas.endTime or 0
    msgs.data = packBossInfo(datas.boss)
    msgs.team = packBossTeam(datas.team or {})
    msgs.buyCnt = datas.buyCnt or 0
    msgs.autoFight = datas.autoFight or 0

    --tools.ss(msgs)
    net.sendMsg2Client(player, ProtoDef.ResBossInfo.name, msgs)
end

local function ReqSaveBossFormation(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqSaveBossFormation no datas", pid)
        return
    end

    local team = proto.team

    local teamId = team.id
    if teamId <= 0 then
        print("ReqSaveBossFormation 0 teamId", pid)
        return
    end

    local list = {}
    local heroIds = team.heroIds
    for k, v in pairs(heroIds) do
        if v == 0 then
            table.insert(list, 1)
        end
    end

    local cnt = #heroIds
    if cnt > 5 then
        print("ReqSaveBossFormation over heros", pid)
        return
    end

    if #list >= cnt then
        print("ReqSaveBossFormation no heros", pid)
        return
    end

    local myTeam = datas.team
    local sid = tostring(teamId)
    myTeam[sid] = tools.clone(heroIds)

    saveData(player)

    net.sendMsg2Client(player, ProtoDef.ResSaveBossFormation.name, proto)

end

local function ReqBossTiliTimeEnd(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqBossTiliTimeEnd no datas", pid)
        return
    end

    local id = define.currencyType.bossTili
    local maxTili = system0Config.manageGameplayStamina
    local now = bagsystem.getCurrencyNumById(player, id)
    if now >= maxTili then
        return
    end

    local curTime = gTools:getNowTime()
    local endTime = datas.endTime or 0

    if endTime > 0 then
        local leftTime = curTime - endTime
        if leftTime < 0 then
            leftTime = math.abs(leftTime)
            if leftTime >= 2 then
                print("ReqBossTiliTimeEnd no com", pid, leftTime, curTime, endTime)
                return
            end
        end

        local perTime = system0Config.staminaRecover[1]
        local perCnt = system0Config.staminaRecover[2]
        local leftCnt = maxTili - now
        
        perCnt = tools.getMinVal(perCnt, leftCnt)

        local newCnt = now + perCnt
        if newCnt < maxTili then
            endTime = curTime + perTime
            datas.endTime = endTime
        else
            datas.endTime = nil
            endTime = 0
        end
        
        saveData(player)

        bagsystem.addItems(player, {{id=id,type=define.itemType.currency,count=perCnt}},define.rewardTypeDefine.notshow)

        net.sendMsg2Client(player, ProtoDef.ResBossTiliTimeEnd.name, {endTime = endTime})
    else
        print("ReqBossTiliTimeEnd no time", pid)
    end
end

local function ReqBossSaodang(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqBossSaodang no datas", pid)
        return
    end

    local id = proto.id
    local idx = proto.idx
    local cnt = proto.cnt

    local cfg = getCheckpointCfg(id, idx)
    if not cfg then
        print("ReqBossSaodang no cfg", pid, id, idx)
        return
    end

    if cnt <= 0 then
        print("ReqBossSaodang 0 cnt", pid)
        return
    end


    local sid = tostring(id)

    local boss = datas.boss or {}
    local data = boss[sid]
    if not data then
        print("ReqBossSaodang no data", pid, id)
        return
    end

    local sidx = tostring(idx)
    local idxData = data[sidx]
    if not idxData then
        print("ReqBossSaodang no idxData", pid, id, idx)
        return
    end

    local list = {}
    local maxHarm = idxData.maxHarm or 0
    for k, v in ipairs(cfg.bossHarm) do
        if maxHarm >= v then
            local rd = cfg.rewardId[k]
            if rd then
                tools.mergeRewardArr(list, rd)  
            end
        end
    end

    if next(list) then
        local consume = cfg.consume
        local price = consume[3]
        local needCnt = cnt * price

        local tiliId = define.currencyType.bossTili
        if not bagsystem.checkAndCostItem(player, {{id=tiliId, count= needCnt, type=define.itemType.currency}}) then
            return
        end

        local rd = dropsystem.getDropItemList(list)
        for k, v in pairs(rd) do
            v.count = v.count * cnt
        end

        bagsystem.addItems(player, rd)


        local endTime = datas.endTime or 0
        if endTime == 0 then
            local curTime = gTools:getNowTime()
            local perTime = system0Config.staminaRecover[1]
            local endTime= curTime + perTime
    
            datas.endTime = endTime
    
            saveData(player)
    
            net.sendMsg2Client(player, ProtoDef.ResBossTiliTimeEnd.name, {endTime = endTime})
        end

    end

end

local function compareValues(x, y)
    return x.value > y.value
end

local function ReqStartFightBoss(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqStartFightBoss no datas", pid)
        return
    end

    local id = proto.id
    local idx = proto.idx
    local teamId = proto.teamId


    local cfg = getCheckpointCfg(id, idx)
    if not cfg then
        print("ReqStartFightBoss no cfg", pid, id, idx)
        return
    end

    local consume = cfg.consume
    local price = consume[3]

    if not bagsystem.checkItemEnough(player, {{id=define.currencyType.bossTili,count=price,type=define.itemType.currency}}) then
        return
    end


    local sid = tostring(id)

    local boss = datas.boss or {}
    local data = boss[sid]
    if not data then
        print("ReqStartFightBoss no data", pid, id)
        return
    end

    local sidx = tostring(idx)
    local idxData = data[sidx]
    if not idxData then
        print("ReqStartFightBoss no idxData", pid, id, idx)
        return
    end

    local team = data.team
    if not team then
        print("ReqStartFightBoss no team", pid, id, idx)
        return
    end

    local steamId = tostring(teamId)
    local teamData = team[steamId]
    if not teamData then
        print("ReqStartFightBoss no teamData", pid, id, idx, teamId)
        return
    end

    datas.harms = datas.harm or {}
    local harms = datas.harms

    local heroData = getHeroData(player) or {}
    local historyData = getEquipHistoryData(player) or {}
    local sortedValues = {}

    for key, value in pairs(historyData.unlockPosData or {}) do
        table.insert(sortedValues, {key = key, value = value})
    end

    table.sort(sortedValues, compareValues)

    local allStep = 0
    for i=1, maxForlumaStepCnt do
        local step = sortedValues[i]
        if step then
            allStep = allStep + step
        else
            break
        end
    end

    local averVal = math.floor(allStep / maxForlumaStepCnt)
    if averVal <= 0 then
        averVal = equipMinStep
    end

    local tab = {}
    local maxWeight = 0
    for k, v in ipairs(bossRangeStep) do
        maxWeight = maxWeight + v
        table.insert(tab, {k, maxWeight})
    end

    local heroList = heroData.heroList or {}
    local normalHarmMsg = {}
    local highHarmMsg = {}
    local tmp = {}
    local battleTime = cfg.battleTime
    local attrVal = 0

    for i=1, battleTime do
        attrVal = 0
        for k, v in pairs(teamData) do
            if v > 0 then
                local sid = tostring(v)
                local heroInfo = heroList[sid]
                local heroCfg = heroConfig[v]
                if heroInfo and heroCfg then
                    local lv = heroInfo.level - 1
                    attrVal = attrVal + 
                    (heroCfg.boldness + lv * heroCfg.boldnessLv) + 
                    (heroCfg.demeanor + lv * heroCfg.demeanorLv) +
                    (heroCfg.logistics + lv * heroCfg.logisticsLv) +
                    (heroCfg.react + lv * heroCfg.reactLv)
    
                    local equipList = heroInfo.equipList or {}
                    local list = {}
    
                    for _, eid in pairs(equipList) do
                        local info = bagsystem.getItemInfo(player, pid, eid)
                        if info then
                            local cfg = equipConfig[info.id]
                            if cfg then
                                table.insert(list, cfg.rank)
                            end
                        end
                    end
    
                    local equipLen = #list
                    local harm = 0
                    local step = 0
                    if equipLen > 0 then
                        step = list[math.random(1, list)]
                        local val = bagsystem.getEquipStepFoodVal(step)
                        harm = val * system0Config.heroEquipmagnification
                    else
                        local rval = math.random(1, maxWeight)
                        for k, v in ipairs(tab) do
                            if rval <= v[2] then 
                                step = averVal + v[1]
                                if step <= 0 then
                                    step = equipMinStep
                                end
                                if step > equipMaxStep then
                                    step = equipMaxStep
                                end
                            end
                        end   
    
                        local val = bagsystem.getEquipStepFoodVal(step)
                        harm = val
                    end
    
                    if tools.isInArr(cfg.bossFavorite, step) then
                        harm = harm * harmFixedVal
                    end
    
                    local msg = {}
                    msg.heroId = v
                    msg.step = step
                    msg.harm = harm
    
                    table.insert(normalHarmMsg, msg)
    
                    harms[sid] = (harms[sid] or 0) + harm
    
                end
            end
        end
    end


    local manageValue = cfg.manageValue
    local feedingFrenzyCD = system0Config.feedingFrenzyCD
    local nowIdx = 1
    attrVal = math.floor(attrVal)
    for idx, needAttr in ipairs(manageValue) do
        if attrVal >= needAttr then
            nowIdx = idx
        end 
    end

    local cd = feedingFrenzyCD[nowIdx]
    local cnt = math.floor(battleTime / cd)
    local feedingFrenzyduration = cfg.feedingFrenzyduration


    local msgs = {}
    msgs.id = id
    msgs.idx = idx
    msgs.normalHarm = {}
    msgs.highHarm = {}
    msgs.teamId = teamId

    net.sendMsg2Client(player, ProtoDef.ResStartFightBoss.name, msgs)

end

local function ReqBossFightCheck(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqBossFightCheck no datas", pid)
        return
    end

    local id = proto.id
    local idx = proto.idx
    local teamId = proto.teamId

    local cfg = getCheckpointCfg(id, idx)
    if not cfg then
        print("ReqBossFightCheck no cfg", pid, id, idx)
        return
    end

    local sid = tostring(id)

    local boss = datas.boss or {}
    local data = boss[sid]
    if not data then
        print("ReqBossFightCheck no data", pid, id)
        return
    end

    local sidx = tostring(idx)
    local idxData = data[sidx]
    if not idxData then
        print("ReqBossFightCheck no idxData", pid, id, idx)
        return
    end

    local consume = cfg.consume
    local price = consume[3]
    if not bagsystem.checkItemEnough(player, {{id=define.currencyType.bossTili,count=price,type=define.itemType.currency}}) then
        return
    end

    local team = datas.team
    if not team then
        print("ReqBossFightCheck no team", pid, id, idx)
        return
    end

    local steamId = tostring(teamId)
    local teamData = team[steamId]
    if not teamData then
        print("ReqBossFightCheck no teamData", pid, id, idx, teamId)
        return
    end

    datas.teamId = teamId
    saveData(player)

    net.sendMsg2Client(player, ProtoDef.ResBossFightCheck.name, {})
end

local function ReqBossClietFightEnd(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqBossClietFightEnd no datas", pid)
        return
    end

    local id = proto.id
    local idx = proto.idx
    local cnt = proto.cnt
    local maxHarm = proto.maxHarm

    local conf = manageGameplayConfig[id]
    if not conf then
        print("ReqBossClietFightEnd no conf", pid, id, id)
        return
    end

    local chapter = conf.chapter
    local cfg = chapter[idx][1]
    if not cfg then
        print("ReqBossClietFightEnd no cfg", pid, id, idx)
        return
    end

    local maxChapterId = 0
    for k, v in pairs(chapter) do
        if k > maxChapterId then
            maxChapterId = k
        end
    end

    local sid = tostring(id)

    local boss = datas.boss or {}
    local data = boss[sid]
    if not data then
        print("ReqBossClietFightEnd no data", pid, id)
        return
    end

    local sidx = tostring(idx)
    local idxData = data[sidx]
    if not idxData then
        print("ReqBossClietFightEnd no idxData", pid, id, idx)
        return
    end

    local team = datas.team
    if not team then
        print("ReqBossClietFightEnd no team", pid, id, idx)
        return
    end

    local steamId = tostring(datas.teamId)
    local teamData = team[steamId]
    if not teamData then
        print("ReqBossClietFightEnd no teamData", pid, id, idx, steamId)
        return
    end

    local heroData = getHeroData(player) or {}
    local heroList = heroData.heroList or {}
    
    local attrData = _G.HeroAttrData[pid]
    local attrVal= 0
    local boldnessAttrId = define.heroAttrType.BOLDNESS
    local demeanorAttrId = define.heroAttrType.DEMEANOR
    local logisticsAttrId = define.heroAttrType.LOGISTICS
    local reactAttrId = define.heroAttrType.REACT

    for _, v in pairs(teamData) do
        if v > 0 then
            local heroAttr = attrData[v] or {}
            attrVal = attrVal + (heroAttr[boldnessAttrId] or 0)
            attrVal = attrVal + (heroAttr[demeanorAttrId] or 0)
            attrVal = attrVal + (heroAttr[logisticsAttrId] or 0)
            attrVal = attrVal + (heroAttr[reactAttrId] or 0)
        end
    end

    local manageValue = cfg.manageValue
    local maxLen = #manageValue
    local feedingFrenzyCD = system0Config.feedingFrenzyCD
    local nowIdx = 0
    attrVal = math.ceil(attrVal)
    if attrVal < manageValue[1] then
        nowIdx = 1
    elseif attrVal >= manageValue[maxLen] then
        nowIdx = maxLen
    else
        for i=1, maxLen do
            if attrVal >= manageValue[i] and attrVal < manageValue[i+1] then
                nowIdx = i
                break
            end
        end
    end

    if nowIdx == 0 then
        print("ReqBossClietFightEnd no nowIdx", pid, id, idx, maxHarm, attrVal)
        return
    end

    local msgs = {id=id,idx=idx,cnt=cnt,maxHarm=maxHarm}
    local cd = feedingFrenzyCD[nowIdx]
    local realCnt = math.ceil(cfg.battleTime / cd)
    local code = 0
    if cnt > realCnt then
        print("ReqBossClietFightEnd no cnt err", pid, id, idx, cnt, realCnt, maxHarm, attrVal)
        msgs.code = 1
        net.sendMsg2Client(player, ProtoDef.ResBossClietFightEnd.name, msgs)
        return
    end

    local list = {}

    local hisHarm = idxData.maxHarm or 0
    if maxHarm > hisHarm then
        idxData.maxHarm = maxHarm
    end

    for k, v in ipairs(cfg.bossHarm) do
        if maxHarm >= v then

            if k == 1 then
                if idx == maxChapterId then
                    local nextId = id + 1
                    local nextConf = manageGameplayConfig[nextId]
                    if nextConf then
                        local snextId = tostring(nextId)
                        if boss[snextId] == nil then
                            local nextIdx = getChapterMinIdx(nextConf.chapter)
                             boss[snextId] = {[tostring(nextIdx)]={}}
                        end
                    end
                else
                    local nextIdx = idx + 1
                    local snextIdx = tostring(nextIdx)
                    if chapter[nextIdx] and data[snextIdx] == nil then
                        data[snextIdx] = {}
                    end
                end
            end

            local rd = cfg.rewardId[k]
            if rd then
                tools.mergeRewardArr(list, rd)  
            end
        end
    end

    if next(list) then
        local consume = cfg.consume
        bagsystem.costItems(player, {{id=define.currencyType.bossTili,count=consume[3],type=define.itemType.currency}})

        local rd = dropsystem.getDropItemList(list)
        bagsystem.addItems(player, rd, define.rewardTypeDefine.notshow)
        --bagsystem.addItems(player, rd)

        if datas.endTime == nil then
            local curTime = gTools:getNowTime()
            local perTime = system0Config.staminaRecover[1]
            local endTime= curTime + perTime
    
            datas.endTime = endTime
            net.sendMsg2Client(player, ProtoDef.ResBossTiliTimeEnd.name, {endTime = endTime})
        end


        saveData(player)


    end

    net.sendMsg2Client(player, ProtoDef.ResBossClietFightEnd.name, msgs)

end

local function UpdateBossTiliTime(player, pid, id, count, price, costId, costType)
    local datas = getData(player)
    if not datas then
        return
    end

    local buyCnt = datas.buyCnt or 0
    local maxBuy = system0Config.staminaFrequency
    if buyCnt >= maxBuy then
        print("UpdateBossTiliTime max buy", pid)
        return
    end

    local leftCnt = maxBuy - buyCnt
    if count > leftCnt then
        print("UpdateBossTiliTime over buycnt", pid)
        return
    end

    if not bagsystem.checkAndCostItem(player, {{id=costId,type=costType,count=price*count}}) then
        return
    end


    buyCnt = buyCnt + count
    datas.buyCnt = buyCnt

    local now = bagsystem.getCurrencyNumById(player, id)
    local maxTili = system0Config.manageGameplayStamina

    local newCnt = count + now
    if newCnt >= maxTili then
        datas.endTime = nil

        net.sendMsg2Client(player, ProtoDef.ResBossTiliTimeEnd.name, {endTime = 0})
    end

    saveData(player)

    net.sendMsg2Client(player, ProtoDef.NotifyBossBuyCntUpdate.name, {buyCnt = buyCnt})

    bagsystem.addItems(player, {{id=id,count=count,type=define.itemType.currency}})
end

local function ReqBossSetAutoFight(player, pid, proto)
    local datas = getData(player)
    if not datas then
        return
    end

    datas.autoFight = proto.autoFight
    saveData(player)
end

local function newDay(player, pid, curTime, isOnline)
    local datas = getData(player)
    if not datas then
        return
    end

    datas.buyCnt = nil
    saveData(player)

    net.sendMsg2Client(player, ProtoDef.NotifyBossBuyCntUpdate.name, {buyCnt = 0})
end

local function login(player, pid, curTime, isfirst)
    local datas = getData(player)
    if not datas then
        return
    end

    local id = define.currencyType.bossTili
    local nowTili = bagsystem.getCurrencyNumById(player, id)
    local maxTili = system0Config.manageGameplayStamina
    if nowTili >= maxTili then
        return
    end

    local endTime = datas.endTime or 0
    if endTime <= 0 then
        return
    end

    if curTime < endTime then
        return
    end

    local perTime = system0Config.staminaRecover[1]

    local recoverNum = system0Config.staminaRecover[2]

    local addCnt, endTime = tools.recoverVal(endTime, curTime, perTime, recoverNum, nowTili, maxTili)

    datas.endTime = endTime

    bagsystem.addItems(player, {{id=id,type=define.itemType.currency,count=addCnt}}, define.rewardTypeDefine.notshow)
        
    saveData(player)
end




local function InitBossData(player)
    local datas = getData(player)
    if not datas then
        return
    end

    datas.team = {}
    datas.boss = {}
    local boss = datas.boss

    local conf = manageGameplayConfig[1]
    local minIdx = getChapterMinIdx(conf.chapter)

    boss[tostring(1)] = {[tostring(minIdx)]={}}

    saveData(player)

    local maxTili = system0Config.manageGameplayStamina
    bagsystem.addItems(player, {{id=define.currencyType.bossTili,type=define.itemType.currency,count=maxTili}}, define.rewardTypeDefine.notshow)

end

local function gmbosslogin(player, pid, args)
    pid = 72101973314635
    player = gPlayerMgr:getPlayerById(pid)
    local curTime = gTools:getNowTime()
    login(player, pid, false, curTime)
end

local function cleanbossdata(player, pid, args)
    pid = 72101973314635
    player = gPlayerMgr:getPlayerById(pid)
    local datas = getData(player)
    tools.cleanTableData(datas)
    InitBossData(player)
    saveData(player)
end

local function showbossdata(player, pid, args)
    pid = 72101973314635
    player = gPlayerMgr:getPlayerById(pid)
    local datas = getData(player)
    tools.ss(datas)
end

local function ReqBossInfobossdata(player, pid, args)
    pid = 72101973314635
    player = gPlayerMgr:getPlayerById(pid)
    ReqBossInfo(player, pid)
end

local function gmReqSaveBossFormation(player, pid, args)
    pid = 72101973314635
    player = gPlayerMgr:getPlayerById(pid)
    ReqSaveBossFormation(player, pid, {team={id=1,heroIds={1,2,3,4,5}}})
end

local function gmReqBossFightCheck(player, pid, args)
    pid = 72101973314635
    player = gPlayerMgr:getPlayerById(pid)
    ReqBossFightCheck(player, pid, {id=1,idx=1001,teamId=1})
end

local function gmReqBossClietFightEnd(player, pid, args)
    pid = 72101973314635
    player = gPlayerMgr:getPlayerById(pid)
    -- ReqBossClietFightEnd(player, pid, {id=1,idx=1002,cnt=2,maxHarm=50000})
    -- ReqBossClietFightEnd(player, pid, {id=1,idx=1003,cnt=2,maxHarm=50000})
    -- ReqBossClietFightEnd(player, pid, {id=1,idx=1004,cnt=2,maxHarm=50000})
    -- ReqBossClietFightEnd(player, pid, {id=1,idx=1005,cnt=2,maxHarm=50000})
    -- ReqBossClietFightEnd(player, pid, {id=1,idx=1006,cnt=2,maxHarm=50000})
    -- ReqBossClietFightEnd(player, pid, {id=1,idx=1007,cnt=2,maxHarm=50000})
    -- ReqBossClietFightEnd(player, pid, {id=1,idx=1008,cnt=2,maxHarm=50000})
    --ReqBossClietFightEnd(player, pid, {id=1,idx=1009,cnt=2,maxHarm=50000})

end

_G.gLuaFuncUpdateBossTiliTime = UpdateBossTiliTime
_G.gLuaFuncInitBossData = InitBossData

event.reg(event.eventType.newDay, newDay)
event.reg(event.eventType.login, login)

gm.reg("gmbosslogin", gmbosslogin)
gm.reg("showbossdata", showbossdata)
gm.reg("cleanbossdata", cleanbossdata)
gm.reg("ReqBossInfobossdata", ReqBossInfobossdata)
gm.reg("gmReqSaveBossFormation", gmReqSaveBossFormation)
gm.reg("gmReqBossFightCheck", gmReqBossFightCheck)
gm.reg("gmReqBossClietFightEnd", gmReqBossClietFightEnd)

net.regMessage(ProtoDef.ReqBossInfo.id, ReqBossInfo, net.messType.gate)
net.regMessage(ProtoDef.ReqBossTiliTimeEnd.id, ReqBossTiliTimeEnd, net.messType.gate)
net.regMessage(ProtoDef.ReqBossSaodang.id, ReqBossSaodang, net.messType.gate)
net.regMessage(ProtoDef.ReqBossSetAutoFight.id, ReqBossSetAutoFight, net.messType.gate)
net.regMessage(ProtoDef.ReqBossClietFightEnd.id, ReqBossClietFightEnd, net.messType.gate)
net.regMessage(ProtoDef.ReqSaveBossFormation.id, ReqSaveBossFormation, net.messType.gate)
net.regMessage(ProtoDef.ReqBossFightCheck.id, ReqBossFightCheck, net.messType.gate)

