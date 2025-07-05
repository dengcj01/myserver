



local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"

local rechargeGiftConfig = require "logic.config.rechargeGiftConfig"

local playermoduledata = require "common.playermoduledata"
local bagsystem = require "logic.system.bagsystem"
local herosystem = require "logic.system.hero.herosystem"
local tasksystem = require "logic.system.tasksystem"
local dropsystem = require "logic.system.dropsystem"
local chargesystem = require "logic.system.chargesystem"

local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.firstChargeGift)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.firstChargeGift)
end




local function ReqFirstChargeGiftInfo(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqFirstChargeGiftInfo no datas", pid)
        return
    end

    local msgs = {data = {}}
    local data = msgs.data
    for k, v in pairs(datas.data) do
        local msg = {}
        msg.status = v.status or define.lockStatusDef.lock
        msg.idxs = v.idxs or {}
        msg.id = tonumber(k)
        
        local day = 0
        if msg.status == define.lockStatusDef.unlock then
            msg.day = v.day
        else
            msg.day = 0
        end
        
        

        table.insert(data, msg)
    end

    --tools.ss(datas)
    --tools.ss(msgs)

    net.sendMsg2Client(player, ProtoDef.ResFirstChargeGiftInfo.name, msgs)
end


local function ReqFirstChargeGiftRecv(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqFirstChargeGiftRecv no datas", pid)
        return
    end

    local idx = proto.idx
    local id = proto.id

    local conf = rechargeGiftConfig[id]
    if not conf then
        print("ReqFirstChargeGiftRecv no conf", pid, id)
        return
    end

    local data = datas.data or {}
    local mdata = data[id]
    if not mdata then
        print("ReqFirstChargeGiftRecv no mdata", pid, id)
        return
    end

    local status = mdata.status or define.lockStatusDef.lock
    if status == define.lockStatusDef.lock then
        print("ReqFirstChargeGiftRecv lock", pid, id)
        return
    end

    mdata.idxs = mdata.idxs or {}
    local idxs = mdata.idxs
    if tools.isInArr(idxs, idx) then
        print("ReqFirstChargeGiftRecv recved", pid, id, idx)
        return
    end


    if idx == 1 then
        if mdata.day ~= 1 then
            print("ReqFirstChargeGiftRecv day err", pid, id, idx)
            return
        end
    else
        local day = mdata.day or 0
        if idx > day then
            print("ReqFirstChargeGiftRecv idx err", pid, id, idx, day)
            return
        end
    end

    local reward = conf.reward
    local dropList = reward[idx]
    if not dropList then
        print("ReqFirstChargeGiftRecv no dropList", pid, id, idx)
        return
    end

    table.insert(idxs, idx)

    local rds = dropsystem.getDropItemList(dropList)

    bagsystem.addItems(player, rds)

    saveData(player)

    net.sendMsg2Client(player, ProtoDef.ResFirstChargeGiftRecv.name, {id=id, idx=idx})
end

local function ReqBuyFirstChargeGift(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqBuyFirstChargeGift no datas", pid)
        return
    end


    local id = proto.id

    local conf = rechargeGiftConfig[id]
    if not conf then
        print("ReqBuyFirstChargeGift no conf", pid, id)
        return
    end

    local data = datas.data or {}
    local mdata = data[id]
    if not mdata then
        print("ReqBuyFirstChargeGift no mdata", pid, id)
        return
    end

    local status = mdata.status or define.lockStatusDef.lock
    if status == define.lockStatusDef.unlock then
        print("ReqBuyFirstChargeGift unlock", pid, id)
        return
    end

    if not bagsystem.checkAndCostItem(player, {{id=define.currencyType.jade, count=conf.value,type=define.itemType.currency}}) then
        return
    end

    mdata.status = define.lockStatusDef.unlock

    saveData(player)

    net.sendMsg2Client(player, ProtoDef.ResBuyFirstChargeGift.name, {id=id})
end


local function login(player, pid, curTime, isfirst)
    local datas = getData(player)
    if not datas then
        return
    end

    datas.data = datas.data or {}
    local data = datas.data
    local ok = false
    for id, info in ipairs(rechargeGiftConfig) do
        if data[id] == nil then
            data[id] = {}
            ok = true
        end
    end

    if ok then
        saveData(player)
    end
    
end

local function newDay(player, pid, curTime, isOnline)
    local datas = getData(player)
    if not datas then
        return
    end

    local ok = false
    for k, v in pairs(datas.data or {}) do
        local idxs = v.idxs or {}
        if next(idxs) then
            v.day = v.day + 1
            ok = true
        end
    end

    if ok then
        saveData(player)
    end
    
    if isOnline then
        net.sendMsg2Client(player, ProtoDef.NotifyFirstChargeGiftNewDay.name, {})
    end
    
end

local function firstChargeGiftCharge(player, pid, order, money, chargeId, extra)
    local gameId = extra.gameId
    local gameChanelId = extra.gameChanelId
    local failRes = define.chargeResult.fail

    local id = extra.id
    local conf = rechargeGiftConfig[id]
    if not conf then
        print("firstChargeGiftCharge no conf", pid, id)
        chargesystem.reportChargeResult(failRes, "首冲配置未找到", order, gameId, gameChanelId)
        return
    end

    local value = conf.value
    if value ~= chargeId then
        print("firstChargeGiftCharge no match chargeId", pid, id, chargeId, value)
        chargesystem.reportChargeResult(failRes, "首冲充值id未匹配", order, gameId, gameChanelId)
        return
    end

    local datas = getData(player)
    if not datas then
        print("firstChargeGiftCharge no datas", pid, id)
        chargesystem.reportChargeResult(failRes, "首冲数据未找到1", order, gameId, gameChanelId)
        return
    end


    local data = datas.data
    if not data then
        print("firstChargeGiftCharge no data", pid, id)
        chargesystem.reportChargeResult(failRes, "首冲数据未找到2", order, gameId, gameChanelId)
        return
    end

    local mdata = data[id]
    if not mdata then
        print("firstChargeGiftCharge no mdata", pid, id)
        chargesystem.reportChargeResult(failRes, "首冲数据未找到3", order, gameId, gameChanelId)
        return
    end

    if mdata.status == define.lockStatusDef.unlock then
        print("firstChargeGiftCharge unlock", pid, id)
        chargesystem.reportChargeResult(failRes, "首冲礼包已解锁", order, gameId, gameChanelId)
        return
    end


    mdata.status = define.lockStatusDef.unlock
    mdata.day = 1

    saveData(player)

    net.sendMsg2Client(player, ProtoDef.NotifyFirstChargeGiftRet.name, {id=id})



    return true
end

local function CheckFirstChargeGift(player, pid)
    login(player, pid)
end


local function showFirstChargeGiftInfo(player, pid, args)
    pid = 72102280429280
    player = gPlayerMgr:getPlayerById(pid)
    ReqFirstChargeGiftInfo(player, pid)
end

local function gmReqFirstChargeGiftRecv(player, pid, args)
    pid = 72102280429280
    player = gPlayerMgr:getPlayerById(pid)
    ReqFirstChargeGiftRecv(player, pid,{id=1,idx=2})
end

local function gmClenaFirstChargeGift(player, pid, args)
    pid = 72102280429280
    player = gPlayerMgr:getPlayerById(pid)
    local datas = getData(player)
    tools.cleanTableData(datas)
    saveData(player)
    login(player, pid)


end

--_G.gLuaFuncCheckFirstChargeGift = CheckFirstChargeGift

event.reg(event.eventType.newDay, newDay)
event.reg(event.eventType.login, login)
event.reg(event.eventType.charge, firstChargeGiftCharge, define.chargeTypeDef.firstChargeGift)



gm.reg("showFirstChargeGiftInfo", showFirstChargeGiftInfo)
gm.reg("gmReqFirstChargeGiftRecv", gmReqFirstChargeGiftRecv)
gm.reg("gmClenaFirstChargeGift", gmClenaFirstChargeGift)

net.regMessage(ProtoDef.ReqFirstChargeGiftInfo.id, ReqFirstChargeGiftInfo, net.messType.gate)
net.regMessage(ProtoDef.ReqFirstChargeGiftRecv.id, ReqFirstChargeGiftRecv, net.messType.gate)
net.regMessage(ProtoDef.ReqBuyFirstChargeGift.id, ReqBuyFirstChargeGift, net.messType.gate)