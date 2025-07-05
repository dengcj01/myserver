

local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"

local cumulativeGiftConfig = require "logic.config.cumulativeGiftConfig"

local playermoduledata = require "common.playermoduledata"
local bagsystem = require "logic.system.bagsystem"
local herosystem = require "logic.system.hero.herosystem"
local tasksystem = require "logic.system.tasksystem"
local dropsystem = require "logic.system.dropsystem"
local chargesystem = require "logic.system.chargesystem"



local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.cumulativeCharge)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.cumulativeCharge)
end

local chargeConditionDef = 
{
    noCondition = 0, -- 无条件
    level = 1, -- 评价等级
    newbieTask = 2, -- 新手任务
    point = 3, -- 关卡
    hero = 4, -- 英雄
}

local cumulativeChargeDef = 
{
    total = 1, -- 全部消费
    charge = 2, -- 直充
    conditionTotal = 3, -- 解锁条件后全部消费
    conditionCharge = 4, -- 解锁条件后直充
}

local function ReqCumulativeChargeInfo(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqCumulativeChargeInfo no datas", pid)
        return
    end

    local msgs = {data = {}}
    local data = msgs.data
    for k, v in pairs(datas.data) do
        local msg = {}
        msg.status = v.status or define.taskRewardDef.noRecv
        msg.money = v.money or 0
        msg.id = tonumber(k)

        
        table.insert(data, msg)
    end


    net.sendMsg2Client(player, ProtoDef.ResCumulativeChargeInfo.name, msgs)
end


local function ReqCumulativeChargeInfoRecv(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqCumulativeChargeInfoRecv no datas", pid)
        return
    end

    local id = proto.id

    local conf = cumulativeGiftConfig[id]
    if not conf then
        print("ReqCumulativeChargeInfoRecv no conf", pid, id)
        return
    end

    local data = datas.data
    if not data then
        print("ReqCumulativeChargeInfoRecv no data", pid, id)
        return
    end

    local mdata = data[id]
    if not mdata then
        print("ReqCumulativeChargeInfoRecv no mdata", pid, id)
        return
    end

    local status = mdata.status or define.taskRewardDef.noRecv
    if status == define.taskRewardDef.recv then
        print("ReqCumulativeChargeInfoRecv recved", pid, id)
        return
    end

    local money = mdata.money or 0
    if money < conf.value then
        print("ReqCumulativeChargeInfoRecv no enough money", pid, id)
        return
    end

    mdata.status = define.taskRewardDef.recv


    local rds = dropsystem.getDropItemList(conf.reward)

    bagsystem.addItems(player, rds)

    saveData(player)

    net.sendMsg2Client(player, ProtoDef.ResCumulativeChargeInfoRecv.name, {id=id})
end

local function isCompleteCondition(player, pid, cumulativeCfg, level, pointId)
    local condition = cumulativeCfg.condition or {}
    local param = cumulativeCfg.param or {}

    for k, condTyep in ipairs(condition) do
        if condTyep == chargeConditionDef.noCondition then
            return true
        end

        local condParam = param[k]
        if not condParam then
            return false
        end

        if condTyep == chargeConditionDef.level then
            if level < condParam then
                return false
            end
        end

        if condTyep == chargeConditionDef.newbieTask then
            if not tasksystem.taskIsCompleteByType(player, condParam, define.taskTypeDef.newPerson) then
                return false
            end
        end

        if condTyep == chargeConditionDef.point then
            if pointId < condParam then
                return false
            end
        end

        if condTyep == chargeConditionDef.hero then
            if not herosystem.checkHasHero(player, condParam) then
                return false
            end
        end
    end

    return true
end


local function UpdateCumulativeMoney(player, pid, order, money, chargeId, extra)
    local datas = getData(player)
    if not datas then
        print("UpdateCumulativeMoney no datas", pid)
        return
    end

    local data = datas.data
    if not data then
        print("UpdateCumulativeMoney no mdata", pid)
        return
    end
    
    local level = player:getLevel()
    local pointId = _G.gluaFuncGetCheckpointId(player)

    local chargeType = extra.type
    local chargeDefault = define.chargeTypeDef.default
    local ok = false --有一次数据变化

    local msgs = {data = {}}
    local cdata = msgs.data
    for k, v in pairs(data) do
        local cumulativeCfg = cumulativeGiftConfig[k]
        if cumulativeCfg then
            local type = cumulativeCfg.type  

            if type == cumulativeChargeDef.total or
             (type == cumulativeChargeDef.charge and chargeType == chargeDefault) or
             (type == cumulativeChargeDef.conditionTotal and isCompleteCondition(player, pid, cumulativeCfg, level, pointId)) or
             (type == cumulativeChargeDef.conditionCharge and chargeType == chargeDefault and isCompleteCondition(player, pid, cumulativeCfg, level, pointId)) then

                ok = true
                v.money = (v.money or 0) + money
                table.insert(cdata, {id=k, money = v.money})
            end
        end
    end

    if not ok then
        print("UpdateCumulativeMoney no money diff", pid)
        return
    end

    saveData(player)

    net.sendMsg2Client(player, ProtoDef.NotifyCumulativeChargeUpdate.name, msgs)
end

local function login(player, pid, curTime, isfirst)
    local datas = getData(player)
    if not datas then
        return
    end

    datas.data = datas.data or {}
    local data = datas.data
    local ok = false
    for id, info in ipairs(cumulativeGiftConfig) do
        if data[id] == nil then
            data[id] = {}
            ok = true
        end


    end

    if ok then
        saveData(player)
    end
    
end

local function gmReqCumulativeChargeInfoRecv(player, pid, args)
    pid = 72103149962374
    player = gPlayerMgr:getPlayerById(pid)
    ReqCumulativeChargeInfoRecv(player, pid, {id=1})
end

_G.gLuaFuncUpdateCumulativeMoney = UpdateCumulativeMoney

gm.reg("gmReqCumulativeChargeInfoRecv", gmReqCumulativeChargeInfoRecv)


event.reg(event.eventType.login, login)

net.regMessage(ProtoDef.ReqCumulativeChargeInfo.id, ReqCumulativeChargeInfo, net.messType.gate)
net.regMessage(ProtoDef.ReqCumulativeChargeInfoRecv.id, ReqCumulativeChargeInfoRecv, net.messType.gate)