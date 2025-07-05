local tools = require "common.tools"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"
local event = require "common.event"

local playermoduledata = require "common.playermoduledata"
local storeGoodsConfig = require "logic.config.storeGoodsConfig"
local storeConfig = require "logic.config.storeConfig"
local bagsystem = require "logic.system.bagsystem"
local msgCode = require "common.model.msgerrorcode"
local util = require "common.util"
local timerMgr = require "common.timer"

local storesystem = {}

--[[
    [商店类型] = {
        list = {[id] = {
          buycount  次数
          discount  折扣
          clearTime
        }}

        refConut  = 刷新次数
        startTime = 刷新时间
    }
]] --
local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.store)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.store)
end

local function getStoreByType(player, id)
    id = tostring(id)
    local data = getData(player)
    if not data.store then
        data.store = {}
    end
    if not data.store[id] then
        data.store[id] = {
            list = {},
            refConut = 0,
            refTime = 0
        }
    end

    return data.store[id]
end

local function addStoreData(player, type, id, cnt, dis)
    type = tostring(type)
    local data = getStoreByType(player, type)

    local temp = {
        buycount = cnt or data.list[id].buycount,
        discount = dis or data.list[id].discount,
        clearTime = gTools:getNowTime()
    }

    data.list[tostring(id)] = temp
end

local function refresh(player, id, extra)
    local list = {}
    local sCofig = storeConfig[id];
    if not sCofig then
        print("refresh  storeConfig not find id:", player:getPid(), id)
        return false
    end


    extra = extra or {}

    local roleLv = player:getLevel()
    local refList = {}
    local cnt = 0
    local totalWeight = 0
    local data = getStoreByType(player, id)
    data.list = {}
    for k, v in pairs(storeGoodsConfig) do
        if roleLv >= (v.roleLevel) then
            local cfg = tools.clone(v)
            if #cfg.discount > 1 then
                cfg.discount = math.floor(math.random(v.discount[1], v.discount[2]))
            else
                cfg.discount = v.discount[1] or 0
            end

            if cfg.store == id then
                if (v.must or 0) >= 1 then
                    addStoreData(player, v.store, v.id, 0, cfg.discount)
                    cnt = cnt + 1
                else
                    totalWeight = totalWeight + v.weight
                    table.insert(refList, cfg)
                end
            end
        end

    end
    -- 指定刷新数量
    if sCofig.goodsCount > 0 then
        local overCnt = sCofig.goodsCount - cnt
        for i = 1, overCnt, 1 do
            local rd = math.random(1, totalWeight)
            for k, v in pairs(refList) do
                if v.weight <= rd then
                    totalWeight = totalWeight - v.weight
                    addStoreData(player, v.store, v.id, 0, v.discount)
                    table.remove(refList, k)
                    break
                end
                rd = rd - v.weight
            end
        end
    else
        -- 全部刷
        for k, v in pairs(refList) do
            addStoreData(player, v.store, v.id, 0, v.discount)
        end
    end

    -- 更新次数和时间
    local data = getStoreByType(player, id)
    if extra.hand then
        data.refConut = (data.refConut or 0) + 1
    end

end

local function writePackage(player, id)
    local msg = {}
    local data = getStoreByType(player, id)
    msg.id = id
    msg.refreshTime = data.refTime
    msg.refCount = data.refConut
    msg.goodsData = {}
    for sid, v in pairs(data.list) do
        table.insert(msg.goodsData, {
            id = tonumber(sid),
            discount = v.discount,
            buyCount = v.buycount
        })
    end

    return msg
end

local function sendStoreData(player)
    local res = {
        sellData = {}
    }
    for k, v in pairs(storeConfig) do
        table.insert(res.sellData, writePackage(player, v.id))
    end

    net.sendMsg2Client(player, ProtoDef.ResStoreOpen.name, res)
end

-- 请求打来商店
local function ReqStoreOpen(player, pid, proto)

    sendStoreData(player)
end

local function sendRefData(player, code, id)
    local res = {}

    res.code = code
    res.sellData = writePackage(player, id)
    net.sendMsg2Client(player, ProtoDef.ResStoreRefresh.name, res)

end

-- 请求刷新
local function ReqStoreRefresh(player, pid, proto)
    local id = proto.id
    local config = storeConfig[id]
    if not config then
        print("ReqStoreRefresh storeConfig config not find")
        sendRefData(player, msgCode.result.null, id)
        return
    end

    local data = getStoreByType(player, id)
    if data.refConut >= (config.refreshCnt or 0) then
        print("ReqStoreRefresh refConut ref full", data.refConut)
        sendRefData(player, msgCode.result.cnt, id)
        return
    end
    local cnt = (data.refConut or 0)  + 1
    local cost = config.refreshCost and config.refreshCost[cnt]
    if not cost then
        cost = config.refreshCost[#config.refreshCost]
    end

    local costItem
    if cost and #cost >= 3 then
        costItem = {
            type = cost[1],
            id = cost[2],
            count = cost[3]
        }
    end

    if costItem then
        if not bagsystem.checkAndCostItem(player, {costItem}) then
            print("ReqStoreRefresh cost item  not enough")
            sendRefData(player, msgCode.result.currencyCost)
            return
        end
    end

    refresh(player, id, {hand=1})
    saveData(player)
    sendRefData(player, msgCode.result.success, id)

end

local function sendBuyData(player, goodsId, list, t, code)
    if not list then
        list = {}
    end
    local res = {}
    res.code = code
    res.storeType = t or 0
    res.goodsData = {
        id = goodsId,
        discount = (list.discount or 0),
        buyCount = (list.buycount or 0)
    }

    net.sendMsg2Client(player, ProtoDef.ResStoreBuy.name, res)
end

-- 请求购买
local function ReqStoreBuy(player, pid, proto)
    local goodsId, goodsCount = proto.goodsId, proto.goodsCount

    local config = storeGoodsConfig[goodsId]
    if not config then
        sendBuyData(player, goodsId, nil, nil, msgCode.result.null)
        print("ReqStoreBuy storeGoodsConfig not find id:", pid, goodsId)
        return
    end
    local data = getStoreByType(player, config.store)
    local itemData = data.list[tostring(goodsId)]
    -- 判断是否可以购买
    if not itemData then
        sendBuyData(player, goodsId, nil, config.store, msgCode.result.fail)
        print("ReqStoreBuy data list  not find id:", pid, goodsId)
        return
    end

    local nowCnt = itemData.buycount or 0
    if config.exchangeLimitCount and config.exchangeLimitCount > 0 and nowCnt >= config.exchangeLimitCount then
        sendBuyData(player, goodsId, itemData, config.store, msgCode.result.fail)
        print("ReqStoreBuy cnt not enough id:", pid, goodsId, itemData.buycount)
        return
    end

    local cost
    if #(config.costItem or {}) >= 3 then
        local count = config.costItem[3] * goodsCount
        if itemData.discount > 0 then
            count = math.floor(config.costItem[3] * (itemData.discount *0.1)) * goodsCount
        end
        cost = {
            type = config.costItem[1],
            id = config.costItem[2],
            count = count
        }
        if count > 0 and  not bagsystem.checkItemEnough(player, {cost}) then
            sendBuyData(player, goodsId, itemData, config.store, msgCode.result.currencyCost)
            print("ReqStoreBuy costitem not enough id:", pid, goodsId, itemData.buycount)
            return false
        end
    end

    local awards = {}
    if config.awards and #config.awards >= 3 then
        table.insert(awards, {
            type = config.awards[1],
            id = config.awards[2],
            count = config.awards[3] * goodsCount
        })
    end

    data.buycount = nowCnt+ goodsCount

    if next(awards)  then
        bagsystem.addItems(player, awards)
    end

    bagsystem.costItems(player, {cost})
    -- 更新玩家数据
    itemData.buycount = itemData.buycount + goodsCount
    sendBuyData(player, goodsId, itemData, config.store, msgCode.result.success)
    saveData(player)

    -- log 日志

end

local function timeBackRef(player, id, refreshTime)
    refresh(player, id)

    local curTime = gTools:getNowTime()
    local data = getStoreByType(player, id)

    data.refTime = curTime
    data.endTime = curTime + refreshTime

    saveData(player)

    timerMgr.addTimer(player, refreshTime, timeBackRef, 0, id, refreshTime)


    sendRefData(player, msgCode.result.success, id)

end

local function resetData(player, pid, curTime, clean)
    local ok = false
    for id, v in pairs(storeConfig) do
        local isOpen = true
        local startDate = v.startDate
        
        if startDate then
            local openTime = gTools:getNowTimeByDate(startDate[1], startDate[2], startDate[3], startDate[4], startDate[5], startDate[6])
            if curTime < openTime then
                isOpen = false
            end
        end

        if isOpen then
            local data = getStoreByType(player, id)
            local endTime = data.endTime or 0
            local refreshTime = v.refreshTime or 0
            local ref = false

            if refreshTime > 0 then
                if endTime == 0 then
                    timerMgr.addTimer(player, refreshTime, timeBackRef, 0, id, refreshTime)
                    data.endTime = curTime + refreshTime
                    data.refTime = gTools:getNowTime()

                else
                    local leftTime = endTime - curTime
                    if leftTime < 0 then
                        leftTime = math.abs(leftTime)
                        data.endTime = curTime + leftTime
                        timerMgr.addTimer(player, leftTime, timeBackRef, 0, id, refreshTime)
                    else
                        ref = true
                        timerMgr.addTimer(player, refreshTime, timeBackRef, 0, id, refreshTime)
                        data.endTime = curTime + refreshTime
                        data.refTime = gTools:getNowTime()
    
                    end
                end
            end

            if clean or ref then
                ok = true
                refresh(player, id)
            end
            

        end

    end

    if ok then
        saveData(player)
    end
    

end


local function newDay(player, pid, curTime, isOnline)
    for k, _ in pairs(storeConfig) do
        local data = getStoreByType(player, k)
        data.list = {}
        data.refConut = 0
        data.refTime = 0
        data.endTime = 0
    end
    
    resetData(player, pid, curTime, true)

end

local function onLogin(player, pid, curTime, isfirst)
    local datas = getData(player)
    if not datas then
        return
    end

    local init = datas.init
    local clean = false
    if not init then
        datas.init = 1
        clean = true
        saveData(player)
    end

    resetData(player, pid, curTime, clean)
end



event.reg(event.eventType.login, onLogin)
event.reg(event.eventType.newDay, newDay)

net.regMessage(ProtoDef.ReqStoreOpen.id, ReqStoreOpen, net.messType.gate)
net.regMessage(ProtoDef.ReqStoreRefresh.id, ReqStoreRefresh, net.messType.gate)
net.regMessage(ProtoDef.ReqStoreBuy.id, ReqStoreBuy, net.messType.gate)

return storesystem

