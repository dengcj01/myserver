local adventuresystem = {}
local gm = require("common.gm")
local util = require "common.util"
local net = require "common.net"
local event = require "common.event"
local define = require "common.define"
local msgCode = require "common.model.msgerrorcode"
local systemConfig = require "logic.config.system"
local battlePointConfig = require "logic.config.battlePoint"
local equipConfig = require "logic.config.equip"
local bagsystem = require "logic.system.bagsystem"
local dropsystem = require "logic.system.dropsystem"
local heroattributesystem = require "logic.system.hero.heroattributesystem"
local playermoduledata = require "common.playermoduledata"
local herosystem = require "logic.system.hero.herosystem"
local tools = require "common.tools"
local tasksystem = require "logic.system.tasksystem"

local defaultId = 1010101

local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.adventure)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.adventure)
end

local function getTeamDataByid(player, id)
    id = tostring(id)
    local data = getData(player)
    if not data.advTeamData then

        data.advTeamData = {}
    end

    return data.advTeamData[id]

end

local function sendAllAdvData(player)
    local data = getData(player)
    local result = {}
    result.advThroughtCount = {}
    for k, v in pairs(data.advThroughtCount or {}) do
        table.insert(result.advThroughtCount, {
            advId = tonumber(k),
            count = v
        })
    end
    result.advSlotCount = data.advSlotCount
    result.advSlotTime = data.advSlotTime

    result.advTeamData = {}
    for k, v in pairs(data.advTeamData or {}) do
        table.insert(result.advTeamData, {
            id = v.id,
            heroIds = v.heroIds
        })
    end

    result.advPlanData = {}
    for k, v in pairs(data.advPlanData or {}) do
        table.insert(result.advPlanData, {
            advId = v.advId,
            heroId = v.heroId,
            attrs = v.attrs,
            startTime = v.startTime
        })
    end

    net.sendMsg2Client(player, ProtoDef.ResAllAdvData.name, result)

    --print("ccccccccccccccccccccccccccccccccccccccccccccccc")
end

local function getAdvPlanData(player, id)
    id = tostring(id)
    local data = getData(player)
    if not data.advPlanData then
        data.advPlanData = {}
    end

    return data.advPlanData[id]
end

local function addAdvPlanData(player, id, heroId, attrId, attrValue)
    local newAdvPlanData = {
        advId = id,
        heroId = heroId,
        startTime = gTools:getNowTime(),
        attrs = {attrId, attrValue}
    }
    local data = getData(player)
    if not data.advPlanData then
        data.advPlanData = {}
    end

    data.advPlanData[tostring(id)] = newAdvPlanData
end



 function adventuresystem.getAdvThroughtCount(player, id)
    id = tostring(id)
    local data = getData(player)
    if not data.advThroughtCount then
        data.advThroughtCount = {}
    end

    return data.advThroughtCount[id] or 0
end
local function addAdvThroughtCount(player, id, cnt)
    id = tostring(id)
    local data = getData(player)
    if not data.advThroughtCount then
        data.advThroughtCount = {}
    end

    data.advThroughtCount[id] = (data.advThroughtCount[id] or 0) + cnt
end

local function removeCollectDataById(player, id)
    id = tostring(id)
    local data = getData(player)
    if data.advPlanData and data.advPlanData[id] then
        data.advPlanData[id] = nil
    end

end

local function sendCollAdvData(player, code, data)
    local msgResult = {}
    msgResult.result = code
    msgResult.advPlanData = {}
    for k, v in pairs(data or {}) do
        table.insert(msgResult.advPlanData, {
            advId = v.advId,
            heroId = v.heroId,
            attrs = v.attrs,
            startTime = v.startTime
        })
    end
    
    net.sendMsg2Client(player, ProtoDef.ResCollectAdv.name, msgResult)

end

local function sendAdvBox(player, code, id, data)
    local res = {}
    res.itemlist = data or {}
    res.id = id
    res.result = code

    net.sendMsg2Client(player, ProtoDef.ResOpenAdvBox.name, res)
end

local function sendCollectData(player, pid, code, data)


    local msgResult = {}

    msgResult.result = code
    msgResult.advPlanData = {}
    for k, v in pairs(data or {}) do
        table.insert(msgResult.advPlanData, {
            advId = v.advId,
            heroId = v.heroId,
            attrs = v.attrs,
            startTime = v.startTime
        })
    end

    net.sendMsg2Client(player, ProtoDef.ResStartCollect.name, msgResult)
end
local function getCollectTiimeRound(startTime)
    local systemcfg = systemConfig[0]
    local timestamp = gTools:getNowTime()
    local collectTime = systemcfg.collectionTime
    local collectMaxTime = systemcfg.collectionMaxTime

    local ctime = math.min(timestamp - startTime, collectMaxTime)
    local overT = math.floor(ctime / collectTime)

    return overT, ctime

end

local function FinishCollect(player, id, itemList, isFinish, isOneKey)
    local systemcfg = systemConfig[0]
    local effect = _G.gluaFuncGetFurnitureEffect(player)
    local advConfig = battlePointConfig[id]
    local collectData = getAdvPlanData(player, id)
    local intfo = getData(player)

    local round, ctime = getCollectTiimeRound(collectData.startTime)
    local collectRate = 0
    for _, data in pairs(advConfig.collectionEfficiency) do
        local value = data[2]
        local rate = data[3]
        if collectData.attrs[2] >= value then
            collectRate = rate
        end
    end

    local through = adventuresystem.getAdvThroughtCount(player, id)
    local isFrish = false
    local firstCollectConfig = systemcfg.gatherReward
    if isOneKey then
        if (intfo.onekey or 0) <= 0  then
            isFrish = true
        end
    elseif through  == 0 then
        if  id == firstCollectConfig[1][1]  then
            isFrish = true
        end
    end

    -- 新手采集处理
    if isFrish  then
        for index, data in pairs(firstCollectConfig) do
            if index > 1 then
                itemList[index - 1] = {id = data[1],count = data[2],type = define.itemType.item}
            end
        end
    elseif round > 0 then
        for _, data in pairs(advConfig.collectionSpeed) do
            local item = {}
            item.id = data[1]
            if effect and effect.gather[item.id] then
                collectRate = collectRate + collectRate * effect.gather[item.id]
            end

            local itemCount = data[2] * round * (collectRate / 10000)
            item.count = math.floor(itemCount)
            local remainder = itemCount * 100 % 100
            if remainder > 0 then
                local isGain = math.random(0, 100) < remainder
                if isGain then
                    item.count = item.count + 1
                end
            end
            item.type = define.itemType.item

            if item.count > 0 then
                table.insert(itemList, item)
            end
           
        end
    end

    if round > 0 then
        local rdT = _G.gluaFuncGetWorkShopEffect(player, define.MAP_TYPE.SEARCH_EXHAUSTIVELY) or 0
        for k, v in pairs(itemList) do
            v.count = math.floor(v.count + v.count * (rdT / 10000))
        end
    end

    if isFrish then
        return 0
    end

    return ctime
end


local function ReqCollectAdv(player, pid, proto)
    local dungeonId, finish = proto.id, proto.finish

    local advData = getData(player)
    local collectData = getAdvPlanData(player, dungeonId)
    if not collectData then
        print("not find collect data", pid)
        sendCollAdvData(player, msgCode.result.fail)
        return
    end

    local timestamp = gTools:getNowTime()
    local collectionTime = systemConfig[0].collectionTime
    local tollalCollectTime = (timestamp - collectData.startTime or 0)

    -- 新手采集处理
    local firstCollectConfig = systemConfig[0].gatherReward
    local through = adventuresystem.getAdvThroughtCount(player, dungeonId)

    -- 如果不是新手采集
    if (((through or 0) == 0) and dungeonId == firstCollectConfig[1][1]) == false then
        if (finish == false and tollalCollectTime < collectionTime) then
            print("collect time not enougt", pid)
            sendCollAdvData(player, msgCode.result.fail)
            return
        end
    end


    local advConfig = battlePointConfig[dungeonId]
    local heroId = collectData.heroId
    local theHero = herosystem.getHeroById(player, heroId)
    if not theHero then
        print("ReqCollectAdv no hero", pid)
        return
    end

    local attrData = _G.HeroAttrData[pid] or {}
    local heroAttrs = attrData[heroId] or {}

    if advConfig then
        local collectionEfficiency = advConfig.collectionEfficiency[1]
        local attributeId = collectionEfficiency[1]
        local minAttrValue = collectionEfficiency[2]

        local attrValue = heroAttrs[attributeId] or 0

        if attrValue < minAttrValue then
            return
        end

        collectData.attrs = {attributeId, attrValue}
    end


    

    local itemList = {}
    local ctime = FinishCollect(player, dungeonId, itemList, finish)
    if ctime > 0 then
        tasksystem.updateProcess(player, pid, define.taskType.collectTime, {ctime}, define.taskValType.add)
    end
    

    if finish then -- 完成并撤下
        removeCollectDataById(player, dungeonId)
    else
        collectData.startTime = gTools:getNowTime()
    end

    addAdvThroughtCount(player, dungeonId, 1)

    if next(itemList) then
        local extra = {enterCache = {}, leaveCache = {}, collect = 1}
        bagsystem.enterCacheSpace(player, pid, itemList, extra.enterCache)
        bagsystem.moveItem(player, pid, extra)
        

        addAdvThroughtCount(player, dungeonId, 1)

        tasksystem.updateProcess(player, pid, define.taskType.collectCnt, {1}, define.taskValType.add)
    end


    if finish == true then
        tasksystem.updateProcess(player, pid, define.taskType.planCollectCnt, {1}, define.taskValType.add, {sub=1}) -- 减少
    end

    sendCollAdvData(player, msgCode.result.success, advData.advPlanData)

    saveData(player)
end

local function ReqOpenAdvBox(player, pid, proto)
    local dungeonId = proto.id
    local advConfig = battlePointConfig[dungeonId]
    if not advConfig or advConfig.type ~= advConfig.type == define.battlePointType.treasure then
        print("not box card",pid,dungeonId)
        sendAdvBox(player, msgCode.result.fail)
        return
    end
    if adventuresystem.getAdvThroughtCount(player, dungeonId) > 0 then
        print("award Received",pid,dungeonId)
        sendAdvBox(player, msgCode.result.fail)
        return true
    end

    local condition = true
    for i, v in pairs(advConfig.unlockId) do
        if  adventuresystem.getAdvThroughtCount(player, v) <= 0 then
            condition = false
        end
    end
    if not condition then
        print("card unlock",pid,dungeonId)
        sendAdvBox(player, msgCode.result.fail)
        return true
    end
    

    local items = dropsystem.getDropItemList(advConfig.firstReward)
    if next(items) then
        bagsystem.addItems(player, items)
    end

    addAdvThroughtCount(player, dungeonId, 1)
    saveData(player);

    sendAdvBox(player, msgCode.result.success, dungeonId, items)

    tasksystem.updateProcess(player, pid, define.taskType.mainCheckpointBox, {1}, define.taskValType.add)

    _G.gluaFuncRatingUnlock(player, pid)
end

local function ReqStartCollect(player, pid, proto)
    local dungeonId, heroId = proto.id, proto.heroId

    local advData = getData(player)
    local collectData = getAdvPlanData(player, dungeonId)
    local advConfig = battlePointConfig[dungeonId]
    if not advConfig or advConfig.type ~= define.battlePointType.collect then
        print("current card not find collect card",pid,dungeonId)
        sendCollectData(player, pid,msgCode.result.fail)
        return
    end

    for i, v in pairs(advConfig.unlockId) do
        if  adventuresystem.getAdvThroughtCount(player, v) <= 0 then
            print("current card unlock",pid,dungeonId)
            sendCollectData(player,pid, msgCode.result.fail)
            return
        end
    end

    local theHero = herosystem.getHeroById(player, heroId)
    if not theHero then
        print("not find hero data", pid, heroId)
        sendCollectData(player,pid,msgCode.result.null)
        return
    end

    local attrData = _G.HeroAttrData[pid] or {}
    local heroAttrs = attrData[heroId] or {}

    local collectionEfficiency = advConfig.collectionEfficiency[1]
    local attributeId = collectionEfficiency[1]
    local minAttrValue = collectionEfficiency[2]

    local attrValue = heroAttrs[attributeId] or 0

    if attrValue < minAttrValue then
        print("collect not enough ", pid,dungeonId)
        sendCollectData(player,pid, msgCode.result.fail)
        return
    end

    local dId = nil
    local advPlanData = advData.advPlanData

    for k, v in pairs(advPlanData) do
        if v.heroId == heroId and v.advId ~= dungeonId then
            dId = v.advId
            break
        end
    end

    local itemList = {}
    if dId then
        local ctime = FinishCollect(player, dId, itemList, true)
        if ctime > 0 then
            tasksystem.updateProcess(player, pid, define.taskType.collectTime, {ctime}, define.taskValType.add)
        end
        
    end

    if dId then
        removeCollectDataById(player, dId)
        addAdvThroughtCount(player, dId, 1)
    end


    if next(itemList) then
        local extra = {collectFlag = 1}
        bagsystem.addItems(player, itemList, define.rewardTypeDefine.collect, nil, extra)
        if extra.code then
            return
        end


        tasksystem.updateProcess(player, pid, define.taskType.collectCnt, {1}, define.taskValType.add)

    end


    local extraTaemNum = _G.gluaFuncGetRatingUnlock(player,define.ratingEfffect.advCollTeam)
    local collectMax =( systemConfig[0].collectionTeam or 0 ) + extraTaemNum
    local count = 0
    for k, v in pairs(advPlanData) do
        count = count + 1
    end

    if count >= collectMax then
        print("dispatch collect team limit pid:" .. pid .. " collectMax:" .. collectMax)
        sendCollectData(player,pid, msgCode.result.full)
        return
    end


    addAdvPlanData(player, dungeonId, heroId, attributeId, attrValue)
    saveData(player)

    sendCollectData(player,pid, msgCode.result.success, advPlanData)

    tasksystem.updateProcess(player, pid, define.taskType.planCollectCnt, {1}, define.taskValType.add) -- 增加

    if next(itemList) then
        bagsystem.addItems(player, itemList, define.rewardTypeDefine.collect)
        tasksystem.updateProcess(player, pid, define.taskType.collectCnt, {1}, define.taskValType.add)
    end
    _G.gluaFuncRatingUnlock(player, pid)
end


local function sendTeamData(player, code, data)
    local result = {}

    result.result = code
    result.advTeamData = {}
    for k, v in pairs(data or {}) do
        table.insert(result.advTeamData, {
            id = v.id,
            heroIds = v.heroIds
        })
    end

    net.sendMsg2Client(player, ProtoDef.ResAdvTeam.name, result)
end

local function ReqAdvTeamUp(player, pid, proto)
    local teamid, heroIds = proto.id, proto.heroIds

    local addCnt = 0
    for k, v in pairs(heroIds) do
        if v > 0 then
            local theHero = herosystem.getHeroById(player, v)
            if not theHero then
                sendTeamData(player, msgCode.result.fail)
                return
            end
            addCnt = addCnt + 1
        end
    end

    local teamdata = getTeamDataByid(player, teamid)

    if teamdata then
        teamdata.heroIds = heroIds
    else
        local advData = getData(player)
        advData.advTeamData[tostring(teamid)] = {
            id = teamid,
            heroIds = heroIds
        }
    end

    saveData(player)
    local advData = getData(player)
    sendTeamData(player, msgCode.result.success, advData.advTeamData)

    tasksystem.updateProcess(player, pid, define.taskType.mainCheckpointFormation, {addCnt}, define.taskValType.add, {teamid})

end

local function sendFightData(player, code)
    local result = {}

    result.result = code or msgCode.result.fail
    net.sendMsg2Client(player, ProtoDef.ResFightStart.name, result)
end

local function refreshTicket(player, advSlotCount, advSlotTime)
    -- 天赋效果
    local effect = _G.gluaFuncGetFurnitureEffect(player)
    local ticketCount = advSlotCount
    local ticketConfig = systemConfig[0].ticket
    local timestamp = gTools:getNowTime()
    local time = ticketConfig[1]
    if effect and effect.recovertTime > 0 then
        time = time - (time * effect.recovertTime)
    end
    
    local count = ticketConfig[2]
    local max = ticketConfig[3]
    local lastTime = advSlotTime
    -- 小于上限先结算
    if ticketCount < max and time > 0 then
        local timeCount = 0
        if lastTime and timestamp > lastTime then
            timeCount = math.floor((timestamp - lastTime) / time)
            ticketCount = ticketCount + timeCount * count
        end
        -- 更新至当前时间的上次刷新时间
        lastTime = lastTime + timeCount * time
        ticketCount = math.min(ticketCount, max)
    end
    return ticketCount, lastTime
end

local function ReqFightStart(player, pid, proto)
    local id, teamid = proto.id, proto.teamid
    local advConfig = battlePointConfig[id]
    if not advConfig then
        print("battlePointConfig not find id:" .. id)
        sendFightData(player)
        return
    end

    local advData = getData(player)

    local condition = true
    for i, v in pairs(advConfig.unlockId) do
        if not adventuresystem.getAdvThroughtCount(player, v) then
            condition = false
        end
    end

    if not condition then
        print("condition fale")
        sendFightData(player)
        return
    end

    if advConfig.type == define.battlePointType.boss or advConfig.type == define.battlePointType.material then
        local ticketCount, lastTime = refreshTicket(player, advData.advSlotCount, advData.advSlotTime)
        -- 只检测不更新
        if ticketCount < advConfig.cost then
            print("tickets not enougt", pid)
            sendFightData(player)
            return
        end
    end

    sendFightData(player, msgCode.result.success)
    return

end

local function sendFightSettle(player, code, items, advSlotCount, advSlotTime)
    local result = {}
    result.itemlist = items or {}
    result.advSlotCount = advSlotCount or 0
    result.advSlotTime = advSlotTime or 0
    result.result = code or msgCode.result.fail

    net.sendMsg2Client(player, ProtoDef.ResFightSettleFix.name, result)
end

local function ReqFightSettleFix(player, pid, proto)
    local id, result = proto.id, proto.result
    local advData = getData(player)

    local advConfig = battlePointConfig[id]
    if not advConfig then
        sendFightSettle(player, msgCode.result.null, nil, advData.advSlotCount, advData.advSlotTime)
        print(" ReqFightSettleFix not find  id:",pid,id)
        return
    end

    if result == 0 then
        sendFightSettle(player, msgCode.result.fail, nil, advData.advSlotCount, advData.advSlotTime)
        local tipMsg = {}
        tipMsg.rdType = define.rewardTypeDefine.fightEnd
        net.sendMsg2Client(player, ProtoDef.NotifyClientRewardTips.name, tipMsg)
        return
    end
    
    advData.id = id
    _G.gluaFuncAddNewFunctionOpen(player)

    local type = advConfig.type
    if type == define.battlePointType.boss or type == define.battlePointType.material then
        local ticketConfig = systemConfig[0].ticket
        local max = ticketConfig[3]
        local ticketCount, lastTime = refreshTicket(player, advData.advSlotCount, advData.advSlotTime)
        if ticketCount < advConfig.cost then
            print("ReqFightSettleFix not enougt", pid,id)
            sendFightSettle(player, msgCode.result.fail)
            net.sendMsg2Client(player, ProtoDef.NotifyClientRewardTips.name, {rdType = define.rewardTypeDefine.fightEnd})
            return
        end


        -- 从满票到缺少
        if ticketCount >= max and (ticketCount - advConfig.cost) < max then
            -- 从此刻开始计算下一次恢复门票
            lastTime = gTools:getNowTime()
        end

        advData.advSlotTime = lastTime
        advData.advSlotCount = ticketCount - advConfig.cost
        tasksystem.updateProcess(player, pid, define.taskType.costTili, {advConfig.cost}, define.taskValType.add)

    end

    local through = adventuresystem.getAdvThroughtCount(player, id)
    local dropReward = advConfig.repeatedReward
    if (through or 0) == 0 then
        dropReward = advConfig.firstReward
    end

    local items = dropsystem.getDropItemList(dropReward)

    if #items > 0 then
        bagsystem.addItems(player, items, define.rewardTypeDefine.fightEnd, nil, {fight=1})
    end

    addAdvThroughtCount(player, id, 1)

    saveData(player)

    sendFightSettle(player, msgCode.result.success, items, advData.advSlotCount, advData.advSlotTime)


    local advThroughtCount = advData.advThroughtCount or {}
    local tab = {}
    for k, v in pairs(advThroughtCount) do
        table.insert(tab, tonumber(k))
    end
    
    tasksystem.updateProcess(player, pid, define.taskType.checkpoint, tab, define.taskValType.cover)
    tasksystem.updateProcess(player, pid, define.taskType.mainCheckpointType, {1}, define.taskValType.add, {type})

    _G.gluaFuncRatingUnlock(player, pid)
end

local function initAdvTeam(player)
    local data = getData(player)
    local count = 0

    if (data.advSlotTime or 0) <= 0 then
        local defaultHeros = systemConfig[0].heroInitialStar
        data.advSlotCount = systemConfig[0].ticket[4]
        data.advTeamData = {}
        data.advTeamData[tostring(1)] = {
            id = 1,
            heroIds = defaultHeros
        }
        data.advSlotTime = gTools:getNowTime()
        saveData(player)
    end
    
end

local function ReqAllAdvData(player, pid, proto)
    --print("cccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111c")
    initAdvTeam(player)
    sendAllAdvData(player)
end

local function sendOneData(player, pid, code)

    local result = {}
    result.code = code
    result.advPlanData = {}
    local tb = getData(player)
    if tb then
        for k, v in pairs(tb.advPlanData or {}) do
            table.insert(result.advPlanData, { advId = v.advId,heroId = v.heroId,
                attrs = v.attrs,startTime = v.startTime})
        end
    end
    
    net.sendMsg2Client(player, ProtoDef.ResOneClickCollect.name, result)
end


local function ReqOneClickCollect(player,pid,proto)
    local data = getData(player)
    local ishasCollect = false
    local itemList = {}

    local attrData = _G.HeroAttrData[pid] or {}


    local maxTime = 0
    for k, collectData in pairs(data.advPlanData or {}) do
        local round, ctime = getCollectTiimeRound(collectData.startTime)
        if round > 0 or (data.onekey or 0 ) <= 0 then
            local advId = tonumber(k)
            local ctime = FinishCollect(player, advId, itemList, false, true)
            maxTime = maxTime + ctime


            local advConfig = battlePointConfig[advId]
            if advConfig then
                local heroAttrs = attrData[collectData.heroId]
                if heroAttrs then
                    local collectionEfficiency = advConfig.collectionEfficiency[1]
                    local attributeId = collectionEfficiency[1]
                    local minAttrValue = collectionEfficiency[2]
    
                    local attrValue = heroAttrs[attributeId] or 0
    
                    if attrValue > minAttrValue then
                        collectData.attrs = {attributeId, attrValue}
                    end
                end

            end

        end
    end

    if maxTime > 0 then
        tasksystem.updateProcess(player, pid, define.taskType.collectTime, {maxTime}, define.taskValType.add)
    end
    

    local extra = {enterCache = {}, leaveCache = {}, collect = 1}
    if next(itemList) == nil then
        bagsystem.moveItem(player, pid, extra)
    else
        bagsystem.enterCacheSpace(player, pid, itemList, extra.enterCache)
        bagsystem.moveItem(player, pid, extra)





        local nowTime = gTools:getNowTime()
        for k, collectData in pairs(data.advPlanData or {}) do
            collectData.startTime = nowTime
            addAdvThroughtCount(player, collectData.adId, 1)
        end
    
        tasksystem.updateProcess(player, pid, define.taskType.collectCnt, {1}, define.taskValType.add)
    end



    data.onekey = 1
    saveData(player)


    sendOneData(player,pid,msgCode.result.success)


    

end

local function ReqOneClickSweeping(player, pid, proto)
    local id = proto.id
    local cnt = proto.cnt

    if cnt <= 0 then
        print("ReqOneClickSweeping no cnt:", pid, id)
        return
    end

    local advData = getData(player) 
    if not advData then
        print("ReqOneClickSweeping no advData:", pid, id)
        return
    end

    local advConfig = battlePointConfig[id]
    if not advConfig then
        print("ReqOneClickSweeping no advConfig:", pid, id)
        return
    end

    local type = advConfig.type
    if type ~= define.battlePointType.boss and type ~= define.battlePointType.material then
        print("ReqOneClickSweeping type err:", pid, id)
        return 
    end

    local advThroughtCount = advData.advThroughtCount or {}
    if not advThroughtCount[tostring(id)] then
        print("ReqOneClickSweeping no advThroughtCount:", pid, id)
        return 
    end

    local ticketCount, lastTime = refreshTicket(player, advData.advSlotCount, advData.advSlotTime)
 
    local cost = advConfig.cost * cnt
    if ticketCount < cost then
        print("ReqOneClickSweeping no ticketCount:", pid, id)
        return
    end

    local itemList = {}
    local repeatedReward = advConfig.repeatedReward
    for i = 1, cnt do
        local items = dropsystem.getDropItemList(repeatedReward)
        for _, v in pairs(items) do
            table.insert(itemList, v)
        end
    end

    bagsystem.addItems(player, itemList)

    local ticketConfig = systemConfig[0].ticket
    local max = ticketConfig[3]

    local nextTicketCount = ticketCount - cost
    if ticketCount >= max and nextTicketCount < max then
        lastTime = gTools:getNowTime()
    end

    advData.advSlotCount = nextTicketCount
    advData.advSlotTime = lastTime

    saveData(player)

    local msg = {}
    msg.id = id
    msg.advSlotCount = nextTicketCount 
    msg.advSlotTime = lastTime

    net.sendMsg2Client(player, ProtoDef.ResOneClickSweeping.name, msg)

    tasksystem.updateProcess(player, pid, define.taskType.costTili, {cost}, define.taskValType.add)
end




local function GetCheckpointId(player)
    local datas = getData(player)
    return datas.id or defaultId
end


local function jumpcheckpoint(player, pid, args)
    local datas = getData(player)
    local id = args[1]
    datas.advThroughtCount = {}
    for k, v in pairs(battlePointConfig) do
        if k <= id then
            datas.advThroughtCount[tostring(k)] = 1
        end
    end
    datas.id = id
    saveData(player)
    
end

local function gmCollectAddItem(player, pid, args)
    pid = 72103755611600
    player = gPlayerMgr:getPlayerById(pid)

    local extra = {enterCache = {}, leaveCache = {}, collect = 1}
    local ret = bagsystem.enterCacheSpace(player, pid, {{id=2001,count=1,type=1}}, extra.enterCache)
    if ret == 2 then
        tools.notifyClientTips(player, "储存空间不足,无法完成采集")
        return
    end

    bagsystem.moveItem(player, pid, extra)

end

local function gmCollectAddItem2(player, pid, proto)
    pid = 72104888118346
    player = gPlayerMgr:getPlayerById(pid)

    ReqOneClickSweeping(player, pid, {id = 1010509, cnt = 5})

end

gm.reg("jumpcheckpoint", jumpcheckpoint)
gm.reg("gmCollectAddItem", gmCollectAddItem)
gm.reg("gmCollectAddItem2", gmCollectAddItem2)

_G.gluaFuncGetCheckpointId = GetCheckpointId


net.regMessage(ProtoDef.ReqAdvTeam.id, ReqAdvTeamUp, net.messType.gate)
net.regMessage(ProtoDef.ReqCollectAdv.id, ReqCollectAdv, net.messType.gate) -- 完成采集/或者扯下来
net.regMessage(ProtoDef.ReqOpenAdvBox.id, ReqOpenAdvBox, net.messType.gate)
net.regMessage(ProtoDef.ReqStartCollect.id, ReqStartCollect, net.messType.gate) -- 设置角色采集
net.regMessage(ProtoDef.ReqFightStart.id, ReqFightStart, net.messType.gate)
net.regMessage(ProtoDef.ReqFightSettleFix.id, ReqFightSettleFix, net.messType.gate)
net.regMessage(ProtoDef.ReqAllAdvData.id, ReqAllAdvData, net.messType.gate)
net.regMessage(ProtoDef.ReqOneClickCollect.id, ReqOneClickCollect, net.messType.gate)
net.regMessage(ProtoDef.ReqOneClickSweeping.id, ReqOneClickSweeping, net.messType.gate)

return adventuresystem
