

local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"



local activitybasesystem = require "logic.system.activity.activitybasesystem"
local bagsystem = require "logic.system.bagsystem"
local dropsystem = require "logic.system.dropsystem"


local function getData(player, id)
    return activitybasesystem.getData(player, id)
end

local function saveData(player)
    activitybasesystem.saveData(player)
end

local sevensignsystem = {}

-- 签到状态
local signStatus =
{
    noSign = 0, -- 未签到
    sign = 1, -- 已签到
}


local function ReqEightSignInfo(player, pid, proto)
    local id = proto.id

    local datas = getData(player, id)
    if not datas then
        return
    end

    local msgs = {}
    msgs.id = id
    msgs.days = datas.days or {}
    msgs.loginDay = datas.loginDay
    msgs.status = datas.status or false


    --tools.ss(msgs)
    net.sendMsg2Client(player, ProtoDef.ResEightSignInfo.name, msgs)
end

local function ReqEightSign(player, pid, proto)
    local id = proto.id
    local day = proto.day

    local datas = getData(player, id)
    if not datas then
        return
    end

    local loginDay = datas.loginDay
    if loginDay < day then
        print("ReqEightSign no login", pid, day)
        return
    end

    local conf = activitybasesystem.getConfig(id, define.activeTypeDefine.eightSign)
    if not conf then
        print("ReqEightSign no conf", pid, id, day)
        return
    end

    local idxCfg = conf.days[day]
    if not idxCfg then
        print("ReqEightSign no conf", pid, id, day)
        return
    end

    datas.days = datas.days or {}
    local days = datas.days
    if tools.isInArr(days, day) then
        print("ReqEightSign signed", pid, day)
        return
    end

    table.insert(days, day)

    saveData(player, id)

    local rd = dropsystem.getDropItemList(idxCfg.task_award)

    bagsystem.addItems(player, rd)

    local msgs = {id = id, day = day}

    net.sendMsg2Client(player, ProtoDef.ResEightSign.name, msgs)

end

local function ReqRecvEightSignRd(player, pid, proto)
    local id = proto.id

    local datas = getData(player, id)
    if not datas then
        return
    end

    local status = datas.status or false
    if status then
        print("ReqRecvEightSignRd signed", pid)
        return
    end

    local conf = activitybasesystem.getConfig(id, define.activeTypeDefine.eightSign)
    if not conf then
        print("ReqRecvEightSignRd no conf", pid, id)
        return
    end

    datas.status = true

    local rd = dropsystem.getDropItemList(conf.drop)

    bagsystem.addItems(player, rd, define.rewardTypeDefine.eightSign)

    saveData(player, id)

    local msgs = {id = id}

    net.sendMsg2Client(player, ProtoDef.ResRecvEightSignRd.name, msgs)
end

local function updateLoginDay(datas)
    datas.loginDay = datas.loginDay + 1
    datas.nextTime = tools.getPlayerNextNewDayTime()
end

local function newDay(player, pid, curTime, isOnline)
    local list = activitybasesystem.getSameTypeActivityIdList(player, define.activeTypeDefine.eightSign)
    local ok = false
    for k, id in pairs(list) do 
        local datas = getData(player, id)
        if datas then
            ok = true
            updateLoginDay(datas)

            if isOnline then
                local msgs = {id = id}
                net.sendMsg2Client(player, ProtoDef.NotifyAddSignDay.name, msgs)
            end
        end
    end

    if ok then
        saveData(player)
    end
end

local function login(player, pid, curTime, isfirst)
    local list = activitybasesystem.getSameTypeActivityIdList(player, define.activeTypeDefine.eightSign)
    local ok = false
    for k, id in pairs(list) do
        local datas = getData(player, id)
        if datas then
            if curTime >= datas.nextTime then
                updateLoginDay(datas)
                ok = true
            end
        end
    end

    if ok then
        saveData(player)
    end
end

local function activitiOpen(player, pid, id, type, datas)
    datas.loginDay = 1
    datas.nextTime = tools.getPlayerNextNewDayTime()
end




event.reg(event.eventType.newDay, newDay)
--event.reg(event.eventType.login, login)
activitybasesystem.reg(activitiOpen, define.activeTypeDefine.eightSign, define.activeEventDefine.open)

net.regMessage(ProtoDef.ReqEightSignInfo.id, ReqEightSignInfo, net.messType.gate)

net.regMessage(ProtoDef.ReqEightSign.id, ReqEightSign, net.messType.gate)
net.regMessage(ProtoDef.ReqRecvEightSignRd.id, ReqRecvEightSignRd, net.messType.gate)
