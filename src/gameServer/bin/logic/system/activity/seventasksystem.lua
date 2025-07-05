

local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"
local taskTypeConfig = require "logic.config.taskTypeConfig"
local sevenDailyRewardConfig = require "logic.config.sevenDailyRewardConfig"
local activitytimeConfig = require "logic.config.activitytimeConfig"
local activitytimeGMConfig = require "logic.config.activitytimeGMConfig"
local activitybasesystem = require "logic.system.activity.activitybasesystem"
local bagsystem = require "logic.system.bagsystem"
local dropsystem = require "logic.system.dropsystem"
local tasksystem = require "logic.system.tasksystem"



-- 配置缓存下,加快查找速度
local cacheSevenDailyRewardConfig = {}

for k, v in pairs(sevenDailyRewardConfig) do
    cacheSevenDailyRewardConfig[k] = {}
    local cfg = cacheSevenDailyRewardConfig[k]
    for kk, vv in pairs(v.days) do
        cfg[kk] = {}
        local dayCfg = cfg[kk]
        local cnt = #vv.task_id
        for i=1, cnt do
            local takskId = vv.task_id[i]
            local taskDropId = vv.task_award[i]
            dayCfg[takskId] = taskDropId
        end
    end
end


local function getData(player, id)
    return activitybasesystem.getData(player, id)
end

local function saveData(player)
    activitybasesystem.saveData(player)
end

local function packTask(taksId, taskData)
    local msg = {}
    msg.id = tonumber(taksId)
    msg.state = taskData.state or define.taskRewardDef.noRecv
    msg.progress = taskData.progress or {}

    return msg
end

local function ReqSevenTaskInfo(player, pid, proto)
    local id = proto.id
    local sid = tostring(id)

    local datas = getData(player, sid)
    if not datas then
        print("ReqSevenTaskInfo no datas", pid, id)
        return
    end

    local msgs = {id = id, data = {}}
    local data = msgs.data
    for k, v in pairs(datas) do
        local msg = {}
        msg.day = tonumber(k)
        msg.task = {}
        msg.status = v.status or define.taskRewardDef.noRecv
        local task = msg.task
        
        for taksId, taskData in pairs(v.task or {}) do
            local tmsg = packTask(taksId, taskData)
            table.insert(task, tmsg)
        end

        table.insert(data, msg)
    end

    --tools.ss(msgs)
    net.sendMsg2Client(player, ProtoDef.ResSevenTaskInfo.name, msgs)
end

local function ReqRecvSevenTaskRd(player, pid, proto)
    local id, day, taskId = proto.id, proto.day, proto.taskId
    local sid,sday,staskId = tostring(id),tostring(day),tostring(taskId)

    local datas = getData(player, sid)
    if not datas then
        print("ReqRecvSevenTaskRd no datas", pid, id)
        return
    end

    local dayData = datas[sday]
    if not dayData then
        print("ReqRecvSevenTaskRd no dayData", pid, id, day)
        return
    end

    local conf = activitybasesystem.getConfig(id, define.activeTypeDefine.sevenTask)
    if not conf then
        print("ReqRecvSevenTaskRd no conf", pid, id, day)
        return
    end

    local dayCfg = conf.days[day]
    if not dayCfg then
        print("ReqRecvSevenTaskRd no dayCfg", pid, id, day, idx)
        return
    end

    local taskData = dayData.task
    if not taskData then
        print("ReqRecvSevenTaskRd no taskData", pid, id, day, taskId)
        return
    end

    local data = taskData[staskId]
    if not data then
        print("ReqRecvSevenTaskRd no data", pid, id, day, taskId)
        return
    end

    if data.state == define.taskRewardDef.recv then
        print("ReqRecvSevenTaskRd recved", pid, id, day, taskId)
        return
    end

    local cfg = taskTypeConfig[taskId]
    if not cfg then
        print("ReqRecvSevenTaskRd no cfg", pid, id, day, taskId)
        return
    end

    local progress = data.progress or {}
    for k, v in ipairs(cfg.progress) do
        local val = progress[k] or 0
        if val < v then
            print("ReqRecvSevenTaskRd no com", pid, id, day, taskId)
            return
        end
    end

    local idx = nil
    for k, v in ipairs(dayCfg.task_id) do
        if v == taskId then
            idx = k
        end
    end
    
    if not idx then
        print("ReqRecvSevenTaskRd no idx", pid, id, day, taskId)
        return
    end
    
    local dropId = dayCfg.task_award[idx]
    local rd = dropsystem.getDropItemList(dropId)
    bagsystem.addItems(player, rd)
    
    data.state = define.taskRewardDef.recv

    saveData(player)

    net.sendMsg2Client(player, ProtoDef.ResRecvSevenTaskRd.name, {id=id,day=day,taskId=taskId})
end

local function ReqRecvAllSevenTaskRd(player, pid, proto)
    local id, day = proto.id, proto.day
    local sid,sday = tostring(id),tostring(day)

    local datas = getData(player, sid)
    if not datas then
        print("ReqRecvAllSevenTaskRd no datas", pid, id)
        return
    end

    local dayData = datas[sday]
    if not dayData then
        print("ReqRecvAllSevenTaskRd no dayData", pid, id, day)
        return
    end

    local taskData = dayData.task
    if not taskData then
        print("ReqRecvAllSevenTaskRd no taskData", pid, id, day)
        return
    end

    local conf = activitybasesystem.getConfig(id, define.activeTypeDefine.sevenTask)
    if not conf then
        print("ReqRecvAllSevenTaskRd no conf", pid, id, day)
        return
    end

    local dayCfg = conf.days[day]
    if not dayCfg then
        print("ReqRecvAllSevenTaskRd no dayCfg", pid, id, day)
        return
    end

    for k, taskId in pairs(dayCfg.task_id) do
        local staskId = tostring(taskId)
        local data = taskData[staskId] or {}
        if not data then
            print("ReqRecvAllSevenTaskRd no data", pid, id, day, taskId)
            return
        end

        local tcfg = taskTypeConfig[taskId]
        if not tcfg then
            print("ReqRecvAllSevenTaskRd no tcfg", pid, id, day, taskId)
            return
        end
        
        local progress = data.progress or {}
        for k, v in ipairs(tcfg.progress) do
            local val = progress[k] or 0
            if val < v then
                print("ReqRecvAllSevenTaskRd no com", pid, id, day, taskId)
                return
            end
        end
    end

    local rd = dropsystem.getDropItemList(dayCfg.total_award)
    bagsystem.addItems(player, rd)

    dayData.status = define.taskRewardDef.recv
    saveData(player)

    net.sendMsg2Client(player, ProtoDef.ResRecvAllSevenTaskRd.name, {id=id,day=day})
end


local function UpateSevenTask(player, uplistActivity, cfg, taskId, taskType, val, addType, cond, notice, args)
    local actType = define.activeTypeDefine.sevenTask
    uplistActivity[actType] = uplistActivity[actType] or {}
    local typeData = uplistActivity[actType]
    local list = activitybasesystem.getCacheId(actType)
    local tab = {}
    local ok = false
    for _, id in pairs(list) do
        repeat
            local datas = getData(player, id)
            if not datas then
                break
            end
            local timeConfig = activitytimeConfig[id]
            if not timeConfig then
                timeConfig = activitytimeGMConfig[id]
                if not timeConfig then
                    break
                end
            end

            local conf = cacheSevenDailyRewardConfig[timeConfig.sheetId]
            if not conf then
                break
            end

            for i=1, #conf do
                repeat
                    local dayCfg = conf[i]
                    if not dayCfg then
                        break
                    end 

                    if not dayCfg[taskId] then
                        break
                    end

                    local day = tostring(i)
                    datas[day] = datas[day] or {}
                    local dayData = datas[day]
                    local process = tasksystem.updatePermanentTask(player, cfg, dayData, taskId, taskType, val, addType, cond, notice, args)
    
                    if process then
                        typeData[id] = typeData[id] or {}
                        local dayUp = typeData[id]
                        dayUp[i] = dayUp[i] or {}
                        local up = dayUp[i]

                        table.insert(up, {id=taskId,progress=process})
                        
                    end

                    ok = true
                until true

            end
        until true
    end

    if ok then
        saveData(player)
    end
end

local function NotifySevenTaskUpdate(player, pid, uplist)

    for id, v in pairs(uplist) do
        local msgs = {id = id, data = {}}
        local data = msgs.data

        for day, task in pairs(v) do
            table.insert(data, {day=day,task=task})
        end

        --tools.ss(msgs)
        net.sendMsg2Client(player, ProtoDef.NotifySevenTaskUpdate.name, msgs)
    end
end

local function showseventask(player, pid, args)
    player = gPlayerMgr:getPlayerById(283204927775595)
    local datas = getData(player, 10001)
    tools.ss(datas)

    --ReqSevenTaskInfo(player, 283204630479428,{id=1})
end

local function showcachetaskconf(player, pid, args)
    tools.ss(cacheSevenDailyRewardConfig)
end

local function ReqSevenTaskInfo1(player, pid, args)
    player = gPlayerMgr:getPlayerById(283204570741235)
    --ReqSevenTaskInfo(player, player:getPid(),{id=1})
    --ReqRecvSevenTaskRd(player, player:getPid(),{id=1,day=1,taskId=35001})
    ReqRecvAllSevenTaskRd(player, player:getPid(),{id=1,day=1})
end

local function activitiOpen(player, pid, id, type, datas)
    tasksystem.updateProcess(player, pid, define.taskType.login, {1}, define.taskValType.add)
end

local function activitiClose(player, pid, id, type, datas)

end

activitybasesystem.reg(activitiOpen, define.activeTypeDefine.sevenTask, define.activeEventDefine.open)
--activitybasesystem.reg(activitiClose, define.activeTypeDefine.sevenTask, define.activeEventDefine.close)

_G.gluaFuncUpateSevenTask = UpateSevenTask
_G.gluaFuncNotifySevenTaskUpdate = NotifySevenTaskUpdate

gm.reg("showseventask", showseventask)
gm.reg("showcachetaskconf", showcachetaskconf)
gm.reg("ReqSevenTaskInfo1", ReqSevenTaskInfo1)

net.regMessage(ProtoDef.ReqSevenTaskInfo.id, ReqSevenTaskInfo, net.messType.gate)
net.regMessage(ProtoDef.ReqRecvSevenTaskRd.id, ReqRecvSevenTaskRd, net.messType.gate)
net.regMessage(ProtoDef.ReqRecvAllSevenTaskRd.id, ReqRecvAllSevenTaskRd, net.messType.gate)


