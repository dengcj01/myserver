

local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"
local playermoduledata = require "common.playermoduledata"
local globalmoduledata = require "common.globalmoduledata"
local httpsystem = require "logic.system.httpsystem"

local rechargeConfig = require "logic.config.rechargeConfig"

local bagsystem = require "logic.system.bagsystem"

local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.charge)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.charge)
end


local function getHistoryData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.historyCharge)
end

local function saveHistoryData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.historyCharge)
end


local function getGlobalData()
    return globalmoduledata.getGlobalData(define.globalModuleDefine.charge)
end

local function saveGlobalData()
    globalmoduledata.saveGlobalData(define.globalModuleDefine.charge)
end


local chargesystem = {}

local chargeStatusDef = 
{
    none = 0, -- 未首次充值
    charge = 1, -- 已首次充值
}

local function packChargeInfo(data)
    local msgs = {}
    for k, v in pairs(data) do
        local msg = {}
        msg.chargeId = tonumber(k)
        msg.status = v

        table.insert(msgs, msg)
    end

    return msgs
end

local function ReqChargeInfo(player, pid, proto)
    local datas =  getData(player)
    if not datas then
        return
    end

    local msgs = {}
    msgs.data = packChargeInfo(datas.charge or {})

   -- tools.ss(msgs)
    net.sendMsg2Client(player, ProtoDef.ResChargeInfo.name, msgs)

    
end

function chargesystem.reportChargeResult(player, status, reason, order, gameId, gameChanelId)
    local ok = gParseConfig:isDevelopServer()
    if ok then
        return
    end

    gameChanelId = gameChanelId or "1100015"
    gameId = gameId or "1000"
    local curTime = gTools:getNowTime()
    local info = 
    {
        status = status, 
        reason = reason, 
        app_order_id = order, 
        game_channel_id = gameChanelId, 
        game_id = gameId,
        time = curTime,
    }

    local res = tools.changeHttp(info)
    --print(res)
    httpsystem.sendPostMessage(res, "v1/sync_order_statu?")
end


local function rechargeOnline(player, pid, hisData, cfg, order, money, chargeId, extra)
    if tools.isInArr(hisData, order) then
        print("rechargeOnline yet process", pid, order, chargeId)
        tools.ss(extra)
        return
    end

    local gameId = extra.gameId
    local gameChanelId = extra.gameChanelId
    local failRes = define.chargeResult.fail

    local datas = getData(player)
    if not datas then
        print("recharge no chargeid", pid, chargeId)
        chargesystem.reportChargeResult(failRes, "充值数据未找到", order, gameId, gameChanelId)
        return
    end

    --money = money / 100

    print("rechargeOnline", pid, order, money, chargeId)

    local chargeType = extra.type
    local ret, res = nil, nil
    if chargeType == define.chargeTypeDef.default then
        local sid = tostring(chargeId)
        datas.charge = datas.charge or {}
        local charge = datas.charge

        local count = cfg.reward
        if charge[sid] == nil then
            charge[sid] = chargeStatusDef.charge
            count = count + cfg.firstAward
        else
            count = count + cfg.normalAward
        end

        bagsystem.addItems(player, {{id=define.currencyType.jade,type=define.itemType.currency,count=count}})

        net.sendMsg2Client(player, ProtoDef.NotifyRetCharge.name, {chargeId = chargeId})

    else
        local eventList = event.eventList
        local list = eventList[event.eventType.charge] or {}
        local func = list[chargeType]
        if func then
            ret, res = tools.safeCall(func, player, pid, order, money, chargeId, extra)
        else
            print("rechargeOnline no chargeType", pid, chargeType)
            chargesystem.reportChargeResult(failRes, "充值类型未找到", order, gameId, gameChanelId)
            return
        end
    end

    
    datas.totalMoney = (datas.totalMoney or 0) + money
    saveData(player)

    player:addChargeVal(money)


    if chargeType == define.chargeTypeDef.default or res == true then
        chargesystem.reportChargeResult(define.chargeResult.success, "充值成功", order, gameId, gameChanelId)

        table.insert(hisData, order)
        saveHistoryData(player)
    end


    _G.gLuaFuncUpdateCumulativeMoney(player, pid, order, money, chargeId, extra)
end

local function recharge(data)
    local order = data.order_sn
    local serverId = tonumber(data.server_id)
    local nowServerId = gParseConfig:getServerId()
    local spid = data.role_id
    local pid = tonumber(spid)
    local chargeId = tonumber(data.item_id)
    local money = tonumber(data.money)
    local gameId= data.game_id
    local gameChanelId = data.game_chanel_id
    local failRes = define.chargeResult.fail

    if not pid or pid <= 0 then
        print("recharge server no match", pid)
        chargesystem.reportChargeResult(failRes, "订单中没有玩家id", order, gameId, gameChanelId)
        return
    end

    if serverId ~= nowServerId then
        print("recharge server no match", pid, serverId, nowServerId)
        chargesystem.reportChargeResult(failRes, "充值服务器id不匹配", order, gameId, gameChanelId)
        return
    end

    if money == nil or money <= 0 then
        print("recharge money err", pid, money)
        chargesystem.reportChargeResult(failRes, "充值金额错误", order, gameId, gameChanelId)
        return
    end

    local cfg = rechargeConfig[chargeId]
    if cfg == nil then
        print("recharge no chargeid", pid, chargeId)
        chargesystem.reportChargeResult(failRes, "充值id未找到", order, gameId, gameChanelId)
        return
    end

    local cfgMoney = cfg.value
    if cfgMoney ~= money then
        print("recharge no match money", pid, chargeId, cfgMoney, money)
        chargesystem.reportChargeResult(failRes, "充值金额不匹配", order, gameId, gameChanelId)
        return
    end

    local extra = tools.decode(data.extra_params) 
    extra.gameId = gameId
    extra.gameChanelId = gameChanelId

    local player = gPlayerMgr:getPlayerById(pid)
    if not extra or next(extra) == nil then
        print("recharge no extra", pid, data.extra_params)
        chargesystem.reportChargeResult(failRes, "没有额外数据", order, gameId, gameChanelId)
        return
    end

    local player = gPlayerMgr:getPlayerById(pid)
    --player = nil
    if player then
        local hisData = getHistoryData(player)
        if not hisData then
            print("recharge no hisData", pid, chargeId)
            chargesystem.reportChargeResult(failRes, "充值历史未找到", order, gameId, gameChanelId)
            return
        end

        rechargeOnline(player, pid, hisData, cfg, order, money, chargeId, extra)
    else
        local globalData = getGlobalData()
        if not globalData then
            print("recharge no global globalData", pid)
            chargesystem.reportChargeResult(failRes, "未找到全局数据", order, gameId, gameChanelId)
            return
        end

        globalData[spid] = globalData[spid] or {}
        local data = globalData[spid]

        for k, v in pairs(data) do
            if v.order == order then
                return
            end
        end

        table.insert(data, {order = order, extra = extra, money = money, chargeId = chargeId})
        saveGlobalData()
    end
end

local function ReqStartCharge(player, pid, proto)
    local chargeId, money, extra = proto.chargeId, proto.money, proto.extra
    extra = tools.decode(extra)

    local cfg = rechargeConfig[chargeId]
    if cfg == nil then
        print("ReqStartCharge no chargeid", pid, chargeId)
        return
    end

    local hisData = getHistoryData(player)
    if not hisData then
        print("ReqStartCharge no hisData", pid, chargeId)
        return
    end

    local cfgMoney = cfg.value
    if cfgMoney ~= money then
        print("ReqStartCharge no match money", pid, chargeId, cfgMoney, money)
        return
    end

    
    local order = tostring(gTools:getMillisTime(0))
    rechargeOnline(player, pid, hisData, cfg, order, money, chargeId, extra)
end


local function login(player, pid, curTime, isfirst)
    local globalData = getGlobalData()
    if not globalData then
        return
    end

    local hisData = getHistoryData(player)
    if not hisData then
        return
    end

    local spid = tostring(pid)

    local data = globalData[spid] or {}
    for k, v in pairs(data) do
        local chargeId = v.chargeId
        local cfg = rechargeConfig[chargeId]
        rechargeOnline(player, pid, hisData, cfg, v.order, v.money, chargeId, v.extra)
    end

    globalData[spid] = nil
    saveGlobalData()
end


function chargesystem.getTotalMoney(player)
    local datas = getData(player)
    if not datas then
        return 0
    end

    return datas.totalMoney or 0
end

local function showcharge(player, pid, args)
    pid = 72102123892203
    player = gPlayerMgr:getPlayerById(pid)

    ReqChargeInfo(player, pid)
end

local function gmReqStartCharge(player, pid, args)
    pid = 72103836469357
    player = gPlayerMgr:getPlayerById(pid)
    local extra = {type=0}
    extra = tools.encode(extra)
    ReqStartCharge(player, pid, {chargeId=2,money=30,extra=extra})
end

event.reg(event.eventType.login, login)
event.regHttp(event.optType.charge, event.httpEvent[event.optType.charge].charge, recharge)

gm.reg("showcharge", showcharge)
gm.reg("gmReqStartCharge", gmReqStartCharge)

net.regMessage(ProtoDef.ReqChargeInfo.id, ReqChargeInfo, net.messType.gate)
net.regMessage(ProtoDef.ReqStartCharge.id, ReqStartCharge, net.messType.gate)

return chargesystem