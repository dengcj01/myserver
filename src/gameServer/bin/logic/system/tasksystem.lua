local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"
local util = require "common.util"

local taskTypeConfig = require "logic.config.taskTypeConfig"
local taskFunctionConfig = require "logic.config.taskFunctionConfig"
local systemConfig = require "logic.config.system"
local equipConfig = require "logic.config.equip"

local playermoduledata = require "common.playermoduledata"
local dropsystem = require "logic.system.dropsystem"
local bagsystem = require "logic.system.bagsystem"
local activitybasesystem = require "logic.system.activity.activitybasesystem"

local tasksystem = {}

local TaskTypeConf = {} -- 缓存同类型的任务id

for k, v in pairs(taskTypeConfig) do
    local type = v.type
    TaskTypeConf[type] = TaskTypeConf[type] or {}
    local data = TaskTypeConf[type]

    table.insert(data, k)
end

local restTypeDef = {
    all = 0, -- 重置所有(任务+索引)
    one = 1 -- 重置当任务
}

local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.task)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.task)
end

local function initTaskTime(typeData, idx, zeroTime, cfg, opt)
    typeData.idx = idx -- 当前每日任务索引
    typeData.idList = typeData.idList or {}

    if opt == restTypeDef.all then
        typeData.idxTime = zeroTime + 86400 * (cfg.dailyTaskRefreshTime - 1) + cfg.refreshTime -- 刷新任务索引时间
        -- typeData.idxTime = gTools:getNowTime() + 10
    end

    typeData.idList = {}
    local dailyType = define.taskTypeDef.daily
    for k, v in pairs(taskTypeConfig) do
        local index = v.index or 0
        local kind = v.kind

        if kind == dailyType and index == idx then
            table.insert(typeData.idList, k)
        end
    end

end

local function initTask(player, pid, datas)
    if datas.init then
        return
    end

    datas.list = datas.list or {}
    local list = datas.list
    local nowTime = gTools:getNowTime()
    local zeroTime = gTools:get0Time(nowTime)

    local ok = false

    for k, v in pairs(define.taskTypeDef) do
        local cfg = taskFunctionConfig[v]
        if not cfg then
            print("ReqTaskInfo no cfg", pid, v)
        else
            local type = tostring(v)

            if list[type] == nil then
                list[type] = {}
                if v == define.taskTypeDef.daily then
                    local typeData = list[type]
                    initTaskTime(typeData, 1, zeroTime, cfg, restTypeDef.all)
                end

                ok = true
            end
        end
    end

    if ok then
        datas.init = 1
    end

    tasksystem.updateProcess(player, pid, define.taskType.login, {1}, define.taskValType.add, nil, false)
    tasksystem.updateProcess(player, pid, define.taskType.slotCnt, {1}, define.taskValType.add, nil, false)
    tasksystem.updateProcess(player, pid, define.taskType.extendShop, {1}, define.taskValType.add)
    tasksystem.updateProcess(player, pid, define.taskType.heroAllLv, {1}, define.taskValType.add, nil, nil, {
        ret = {
            [1] = 1
        }
    })
    tasksystem.updateProcess(player, pid, define.taskType.accLogin, {1}, define.taskValType.add, nil, false)
    saveData(player)
end

local function packTaskData(id, taskData)
    local msg = {}
    msg.id = tonumber(id)
    msg.state = taskData.state or define.taskRewardDef.noRecv
    msg.progress = taskData.progress or {}

    return msg
end

local function packTaskTypeData(type, typeData)
    local msg = {
        task = {}
    }
    msg.type = tonumber(type)
    msg.idList = typeData.idList or {}

    local task = msg.task
    for k, v in pairs(typeData.task or {}) do
        local msg = packTaskData(k, v)

        table.insert(task, msg)
    end

    return msg
end

local function ReqTaskInfo(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqTaskInfo no datas", pid)
        return
    end

    local msgs = {
        task = {}
    }
    local task = msgs.task
    for k, v in pairs(datas.list or {}) do
        local msg = packTaskTypeData(k, v)

        table.insert(task, msg)
    end

    net.sendMsg2Client(player, ProtoDef.ResTaskInfo.name, msgs)
end

local function ReqRecvTaskRd(player, pid, proto)

    local type, taskids = proto.type, proto.taskids
    local datas = getData(player)
    if not datas then
        print("ReqTaskInfo no datas", pid)
        return
    end

    local list = datas.list
    if not list then
        print("ReqTaskInfo no list", pid)
        return
    end

    local stype = tostring(type)
    local typeData = list[stype]
    if not typeData then
        print("ReqTaskInfo no typeData", pid, stype)
        return
    end

    local task = typeData.task
    if not task then
        print("ReqTaskInfo no task", pid, stype)
        return
    end
    local awards = {}
    local msg = {
        taskStatus = {}
    }

    local successTaskIds = {}
    local achiType = define.taskTypeDef.achi
    for _, id in pairs(taskids) do
        local sid = tostring(id)
        local data = task[sid]
        if data and (data.state or 0) == define.taskRewardDef.noRecv then
            local cfg1 = taskFunctionConfig[type]
            local cfg = taskTypeConfig[id]
            if cfg and cfg1 then
                local progress = data.progress or {}
                for k, v in ipairs(cfg.progress) do
                    local val = progress[k] or 0
                    if val < v then
                        print("ReqTaskInfo no com", pid, stype, stype, sid)
                        return
                    end
                end

                if type == achiType then
                    if cfg.stage > 1 then
                        local group = cfg.group
                        local preId = id - 1
                        local preCfg = taskTypeConfig[preId]
                        if preCfg then
                            local preGroup = preCfg.group
                            if preGroup then
                                if preGroup ~= group then
                                    print("ReqTaskInfo no same group", pid, id)
                                    return
                                end
    
                                if tasksystem.taskIsCompleteByType(player, sid, achiType) then
                                    print("ReqTaskInfo pre no com", pid, id)
                                    return
                                end
                            end
                        end
                    end

                end

                local rds = dropsystem.getDropItemList(cfg.reward)
                for k, v in pairs(rds) do
                    table.insert(awards, v)
                end
                table.insert(successTaskIds, id)
            end
        end

    end
    if #awards > 0 then
        bagsystem.addItems(player, awards)
    end

    for k, taksid in pairs(successTaskIds) do
        local sid = tostring(taksid)
        local data = task[sid]
        data.state = define.taskRewardDef.recv
        table.insert(msg.taskStatus, {
            id = taksid,
            type = type,
            state = data.state
        })
    end

    saveData(player)
    net.sendMsg2Client(player, ProtoDef.ResRecvTaskRd.name, msg)

    if type == define.taskTypeDef.newPerson then
        _G.gluaFuncAddNewFunctionOpen(player)
        _G.gluaFuncRatingUnlock(player, pid)
    end

    local retType = define.taskType.mainCheckpointRd

    if type == define.taskTypeDef.daily then
        retType = define.taskType.dailyTaskCnt
    end

    tasksystem.updateProcess(player, pid, retType, {1}, define.taskValType.cover)
end



-- 获取当前类型的所有任务id(常驻类型)
local function getThisTaskTypeIdList(cacheIdList, list)
    local res = {}
    local activity = {} -- 活动

    local activityList = activitybasesystem.getCacheTaskId()
    for _, taksId in pairs(cacheIdList) do
        for _, type in pairs(define.taskTypeDef) do
            if not res[type] then
                res[type] = {}
            end

            if type ~= define.taskTypeDef.daily then
                local cfg = taskFunctionConfig[type]
                if cfg then
                    if (taksId >= cfg.range1[1] and taksId <= cfg.range1[2]) or tools.isInArr(cfg.range2, taksId) then


                        res[type][taksId] = 1
                    end
                end
            else
                local typeData = list[tostring(type)] or {}
                local idList = typeData.idList or {}
                if tools.isInArr(idList, taksId) then
                    res[type][taksId] = 1
                end
            end
        end

        if activityList[taksId] then
            activity[taksId] = 1
        end
    end

    return res, activity

end

local function mergeTask(idList, nowList)
    for type, list in pairs(nowList or {}) do
        for k, v in pairs(list or {}) do
            idList[k] = 1
        end
    end
end

function tasksystem.updatePermanentTask(player, cfg, typeData, taskId, taskType, val, addType, cond, notice, args)

    typeData.task = typeData.task or {}
    local task = typeData.task

    local sid = tostring(taskId)

    task[sid] = task[sid] or {}
    local data = task[sid]

    local one = true
    if taskType == define.taskType.comTalkAndRise or taskType == define.taskType.comDisAndSell then
        one = false
    end

    local progress = nil
    if one then
        data.progress = data.progress or {0}
        progress = data.progress

        local count = progress[1]
        local cfgCount = cfg.progress[1]
        if count >= cfgCount and (
        taskType ~= define.taskType.workshopTianfuDian or
        taskType ~= define.taskType.mainCheckpointFormation) then
            return nil
        end

        if taskType == define.taskType.checkpoint then
            local ret = tools.isInArr(val, cfgCount)
            if ret then
                progress[1] = cfgCount
            end
        elseif taskType == define.taskType.planCollectCnt then
            if cond.sub then
                count = count - val[1]
                if count <= 0 then
                    count = 0
                end
            else
                count = count + val[1]
            end
            progress[1] = count
        elseif taskType == define.taskType.mainCheckpointRd or taskType == define.taskType.dailyTaskCnt then
            local minId = cfg.cond[1] or 0
            local maxId = cfg.cond[2] or 0
            local taskEvType = define.taskTypeDef.daily
            if taskType == define.taskType.mainCheckpointRd then
                taskEvType = define.taskTypeDef.chapter
            end

            local comlist = {}
            for i = minId, maxId do
                local ret = tasksystem.taskIsCompleteByType(player, i, taskEvType)
                if ret then
                    table.insert(comlist, 1)
                end
            end
            progress[1] = #comlist
        elseif taskType == define.taskType.workShopAddCnt then
            progress[1] = val[1]
        elseif taskType == define.taskType.furnitureLevel then
            local upVal = val[1]
            if upVal >= cfgCount then
                progress[1] = upVal
            end
        elseif taskType == define.taskType.workshopTianfuDian or 
        taskType == define.taskType.mainCheckpointFormation then
            if data.state == define.taskRewardDef.recv then
                return nil
            end

            progress[1] = val[1]
        else
            local upVal = val[1]
            if taskType == define.taskType.heroAllLv or taskType == define.taskType.getEquipLvCnt then
                if upVal <= count then
                    return
                end
            end

            if addType == define.taskValType.add then
                count = count + upVal
            else
                count = upVal
            end

            progress[1] = count
        end

    else
        data.progress = data.progress or {0, 0}
        progress = data.progress

        local ok = false
        for k, v in ipairs(cfg.progress) do
            if progress[k] < v then
                ok = true
                break
            end
        end

        if not ok then
            return nil
        end

        if addType == define.taskValType.add then
            for k, v in ipairs(val) do
                progress[k] = progress[k] + v
            end
        else
            for k, v in ipairs(val) do
                progress[k] = v
            end
        end
    end

    return progress

end

local function update(player, uplist, cfg, list, taskId, taskType, val, addType, cond, notice, args, task,
    uplistActivity)
    for k, v in pairs(define.taskTypeDef) do
        if task[v] and task[v][taskId] then
            local process = tasksystem.updatePermanentTask(player, cfg, list[tostring(v)], taskId, taskType, val,
                addType, cond, notice, args)

            if process then
                local msg = {}
                msg.id = taskId
                msg.process = process

                table.insert(uplist[v], msg)
            end
        end
    end

    _G.gluaFuncUpateSevenTask(player, uplistActivity, cfg, taskId, taskType, val, addType, cond, notice, args)
end

local function chekCond(player, condition)
    local lv = player:getLevel()
    for k, v in ipairs(condition) do
        if v ~= 0 then
            if k == 1 and lv < v then
                return
            end

            if k == 2 and (not tasksystem.taskIsCompleteByType(player, v, define.taskTypeDef.chapter)) then
                return
            end

            if k == 3 and (not _G.gluaFuncFuntionIsOpen(player, v)) then
                return
            end
        end

    end

    return true
end

local function chekPreTaskIsComplete(player, taksId)
    if not taksId or taksId == 0 then
        return true
    end

    local cfg = taskTypeConfig[taksId]
    if not cfg then
        return
    end

    local ret = tasksystem.taskIsCompleteByType(player, taksId, cfg.kind)
    return ret
end

-- 任务系统外部统一更新接口
function tasksystem.updateProcess(player, pid, taskType, val, addType, cond, notice, args)
    val = val or {}
    if #val <= 0 then
        print("tasksystem.update val is 0", pid)
        return
    end

    local vals = tools.clone(val)

    local datas = getData(player)
    if not datas then
        return
    end

    initTask(player, pid, datas)

    local cacheIdList = TaskTypeConf[taskType]
    if not cacheIdList then
        return
    end

    local list = datas.list
    local res, activity = getThisTaskTypeIdList(cacheIdList, list)

    local idList = {}
    mergeTask(idList, res)

    for k, v in pairs(activity) do
        idList[k] = 1
    end

    cond = cond or {}
    args = args or {}

    if notice == nil then
        notice = true
    end

    local uplist = {}
    for k, v in pairs(define.taskTypeDef) do
        uplist[v] = {}
    end

    local uplistActivity = {}


    for taskId, _ in pairs(idList) do
        repeat
            local cfg = taskTypeConfig[taskId]
            if cfg then
                if not chekCond(player, cfg.condition) then
                    break
                end

                if not chekPreTaskIsComplete(player, cfg.taskUnlock) then
                    break
                end

                local funcId = cfg.functionOpne or 0
                if funcId > 0 and (not _G.gluaFuncFuntionIsOpen(player, cfg.functionOpne)) then
                    break
                end


                local ok = true
                local cfgCond = cfg.cond
                local len = #cfgCond

                if taskType == define.taskType.makeEquip or 
                taskType == define.taskType.sellEquipCnt or 
                taskType == define.taskType.takonEquip or
                taskType == define.taskType.forgeCnt or 
                taskType == define.taskType.lockWorkShopCnt or 
                taskType == define.taskType.furnitureCnt or 
                taskType == define.taskType.upHeroLevelOrStep or 
                taskType == define.taskType.furnitureLevel or 
                
                taskType == define.taskType.makeEquipQuality1 or 
                taskType == define.taskType.makeEquipQuality2 or 
                taskType == define.taskType.makeEquipQuality3 or 
                taskType == define.taskType.makeEquipQuality4 or 
                taskType == define.taskType.makeEquipQuality5 or 
                taskType == define.taskType.makeEquipQuality6 or 
                taskType == define.taskType.makeEquipQuality7 or 
                taskType == define.taskType.makeEquipQuality8 or 
                taskType == define.taskType.makeEquipQuality9 or 
                taskType == define.taskType.makeEquipQuality10 or 
                taskType == define.taskType.makeEquipQuality11 or 
                taskType == define.taskType.makeEquipQuality12 or 
                taskType == define.taskType.makeEquipQuality13 or 
                taskType == define.taskType.makeEquipQuality14 or 
                taskType == define.taskType.makeEquipQuality15 or 
                taskType == define.taskType.makeEquipQuality16 or 
                taskType == define.taskType.makeEquipQuality17 or 
                taskType == define.taskType.makeEquipQuality18 or 
                taskType == define.taskType.makeEquipQuality19 or 
                taskType == define.taskType.makeEquipQuality20 or 
                taskType == define.taskType.makeEquipQuality21 or 
                taskType == define.taskType.makeEquipQuality22 or 
                taskType == define.taskType.makeEquipQuality23 or 
                taskType == define.taskType.makeEquipQuality24 or 
                taskType == define.taskType.makeEquipQuality25 or 
                taskType == define.taskType.makeEquipQuality26 or 

                taskType == define.taskType.activeEquip1 or 
                taskType == define.taskType.activeEquip2 or 
                taskType == define.taskType.activeEquip3 or 
                taskType == define.taskType.activeEquip4 or 
                taskType == define.taskType.activeEquip5  or 
                taskType == define.taskType.activeEquip6  or 
                taskType == define.taskType.activeEquip7  or 
                taskType == define.taskType.activeEquip8  or 
                taskType == define.taskType.activeEquip9  or 
                taskType == define.taskType.activeEquip10  or 
                taskType == define.taskType.activeEquip11  or 
                taskType == define.taskType.activeEquip12  or 
                taskType == define.taskType.activeEquip13  or 
                taskType == define.taskType.activeEquip14  or 
                taskType == define.taskType.activeEquip15  or 
                taskType == define.taskType.activeEquip16  or 
                taskType == define.taskType.activeEquip17  or 
                taskType == define.taskType.activeEquip18  or 
                taskType == define.taskType.activeEquip19  or 
                taskType == define.taskType.activeEquip20  or 
                taskType == define.taskType.activeEquip21  or 
                taskType == define.taskType.activeEquip22  or 
                taskType == define.taskType.activeEquip23  or 
                taskType == define.taskType.activeEquip24  or 
                taskType == define.taskType.activeEquip25  or 
                taskType == define.taskType.activeEquip26  or 

                taskType == define.taskType.equipProcess1 or 
                taskType == define.taskType.equipProcess2 or 
                taskType == define.taskType.equipProcess3 or 
                taskType == define.taskType.equipProcess4 or 
                taskType == define.taskType.equipProcess5 or 
                taskType == define.taskType.equipProcess6 or 
                taskType == define.taskType.equipProcess7 or 
                taskType == define.taskType.equipProcess8 or 
                taskType == define.taskType.equipProcess9 or 
                taskType == define.taskType.equipProcess10 or 
                taskType == define.taskType.equipProcess11 or 
                taskType == define.taskType.equipProcess12 or 
                taskType == define.taskType.equipProcess13 or 
                taskType == define.taskType.equipProcess14 or 
                taskType == define.taskType.equipProcess15 or 
                taskType == define.taskType.equipProcess16 or 
                taskType == define.taskType.equipProcess17 or 
                taskType == define.taskType.equipProcess18 or 
                taskType == define.taskType.equipProcess19 or 
                taskType == define.taskType.equipProcess20 or 
                taskType == define.taskType.equipProcess21 or 
                taskType == define.taskType.equipProcess22 or 
                taskType == define.taskType.equipProcess23 or 
                taskType == define.taskType.equipProcess24 or 
                taskType == define.taskType.equipProcess25 or 
                taskType == define.taskType.equipProcess26 or 

                taskType == define.taskType.makeEquipState or
                taskType == define.taskType.makeEquipStateQuality or 
                taskType == define.taskType.raiseAndSell or
                taskType == define.taskType.disAndSell or 
                taskType == define.taskType.furnitureLevelType or 
                taskType == define.taskType.mainCheckpointType or 
                taskType == define.taskType.achiPageCount or 
                taskType == define.taskType.businessCnt or 
                taskType == define.taskType.heroJingyingLv or
                taskType == define.taskType.raiseOrDiscountCnt or
                taskType == define.taskType.mainCheckpointFormation or
                taskType == define.taskType.makeForlumaId or
                taskType == define.taskType.sellFixEquipCnt or
                taskType == define.taskType.workshopTianfuDian then
                    if cfg.condType == 1 then -- 或关系,满足一个条件就行
                        if taskType == define.taskType.forgeCnt then
                            ok = false
                            for k, v in pairs(cond) do
                                if tools.isInArr(cfgCond, v) then
                                    ok = true
                                    break
                                end
                            end
                        end
                    else
                        if taskType == define.taskType.furnitureLevel then
                            for i, v in ipairs(cfgCond) do
                                local condVal = cond[i]
                                if v ~= 0 and condVal ~= v and i == 1 then
                                    ok = false
                                    break
                                else
                                    if condVal < v then
                                        ok = false
                                        break
                                    end
                                end
                            end

                        elseif taskType == define.taskType.lockWorkShopCnt then
                            ok = false
                            for k, v in pairs(cond) do
                                if tools.isInArr(cfgCond, v) then
                                    ok = true
                                    break
                                end
                            end
                        else
                            for i, v in ipairs(cfgCond or {}) do
                                local condVal = cond[i]
                                if v ~= 0 and condVal ~= v then
                                    ok = false
                                    break
                                end
                            end
                        end
                    end
                elseif taskType == define.taskType.heroAllLv or 
                taskType == define.taskType.getEquipLvCnt or 
                taskType == define.taskType.heroZhanjiLv or 
                taskType == define.taskType.heroPuGongLv or 
                taskType == define.taskType.heroMingzuoLv or 
                taskType == define.taskType.heroBeiDongLv  then
                    local cnt = 0
                    local lv = cfgCond[1]
                    local cfgCnt = cfg.progress[1]
                    for k, v in pairs(args.ret) do
                        k = tonumber(k)
                        if k >= lv then
                            cnt = cnt + v
                        end
                    end

                    vals = {cnt}

                end

                if ok then
                    update(player, uplist, cfg, list, taskId, taskType, vals, addType, cond, notice, args, res, uplistActivity)
                end

            end
        until true

    end

    saveData(player)

    local msgs = {
        task = {}
    }
    local task = msgs.task

    --tools.ss(uplist, "uplist")

    for k, v in pairs(uplist) do
        if next(v) then
            local msg = {
                task = {}
            }
            msg.type = k
            for _, vv in pairs(v) do
                local t = {
                    id = vv.id,
                    progress = vv.process
                }
                table.insert(msg.task, t)
            end
            table.insert(task, msg)
        end
    end

    if next(task) and notice then
        net.sendMsg2Client(player, ProtoDef.NotifyTaskUpdate.name, msgs)
    end

    if next(uplistActivity) then
        for k, v in pairs(uplistActivity) do
            if k == define.activeTypeDefine.sevenTask and next(v) then
                _G.gluaFuncNotifySevenTaskUpdate(player, pid, v)
            end
        end

        activitybasesystem.saveData(player)
    end

end

local function login(player, pid, curTime, isfirst)
    local datas = getData(player)
    if not datas then
        print("task login no datas", pid)
        return
    end

    if isfirst then
        initTask(player, pid, datas)
    end

end

local function newDay(player, pid, curTime, isOnline)
    local datas = getData(player)
    if not datas then
        print("task newDay no datas", pid)
        return
    end

    local ok = false
    local zeroTime = gTools:get0Time(curTime)
    local uplist = {}
    datas.list = datas.list or {}
    local list = datas.list

    for k, v in pairs(define.taskTypeDef) do
        if v == define.taskTypeDef.daily then
            local type = tostring(v)
            local typeData = list[type]
            local cfg = taskFunctionConfig[v]

            if typeData and cfg then
                local ret = false
                local idx = typeData.idx
                if curTime >= typeData.idxTime then
                    local nextIdx = idx + 1
                    if nextIdx > cfg.upperLimit then
                        nextIdx = 1
                        typeData.idx = nextIdx
                    end
                    initTaskTime(typeData, nextIdx, zeroTime, cfg, restTypeDef.all)

                    ret = true
                    ok = true
                end

                if ret == false then
                    initTaskTime(typeData, idx, zeroTime, cfg, restTypeDef.one)
                    ok = true
                end

                if ok then
                    typeData.task = nil
                    table.insert(uplist, {
                        type = v,
                        idList = typeData.idList
                    })
                end
            end
        end
    end

    if ok then
        saveData(player)

        local msgs = {}
        msgs.data = uplist
        net.sendMsg2Client(player, ProtoDef.NotifyTaskReset.name, msgs)

        tasksystem.updateProcess(player, pid, define.taskType.login, {1}, define.taskValType.add)
        tasksystem.updateProcess(player, pid, define.taskType.accLogin, {1}, define.taskValType.add)
    end

end

function tasksystem.isComplete(player, taksId)
    if taksId <= 0 then
        return true
    end
    local datas = getData(player)
    if not datas then
        return false
    end

    for k, v in pairs(datas.list or {}) do
        if tasksystem.taskIsCompleteByType(player, taksId, k) then
            return true
        end
    end

    return false
end

function tasksystem.taskIsCompleteByType(player, taksId, type)
    local datas = getData(player)
    if not datas then
        return false
    end

    local list = datas.list
    if not list then
        return false
    end

    local typeData = list[tostring(type)]
    if not typeData then
        return false
    end

    local task = typeData.task
    if not task then
        return false
    end

    local sid = tostring(taksId)
    local data = task[sid]
    if not data then
        return false
    end

    if data.state == nil or data.state ~= define.taskRewardDef.recv then
        return false
    end

    return true
end

local function gmLogin(player, pid, args)
    login(player, 0, true, gTools:getNowTime())
end

local function gmShowTaskInfo(player, pid, args)
    -- local cfg = equipConfig[2010101]
    -- local kind = bagsystem.getEquipKind(cfg.portion)
    -- local pos = bagsystem.getEquipPos(cfg.portion)

    -- tasksystem.updateProcess(player, pid, define.taskType.makeEquip, {1},define.taskValType.add, {cfg.equipQuality,kind,pos,2010101})
    pid = 72103851252208
    player = gPlayerMgr:getPlayerById(pid)
    local datas = getData(player)
    tools.ss(datas)
end

local function f333(player, pid, args)
    player = gPlayerMgr:getPlayerById(283204139194777)
    -- local t = gPlayerMgr:getOnlinePlayers()

    -- print("xxxxxxxxx",gPlayerMgr:getOnlineCnt())

    -- for k, v in pairs(t) do
    --     print(k,v)
    -- end
    local data = getData(player)

    tools.ss(data)
end

local function f44(player, pid, args)
    player = gPlayerMgr:getPlayerById(283204139194777)
    local datas = getData(player)
    local data = datas.list["1"]
    tools.cleanTableData(data)
    saveData(player)

    -- net.sendMsg2Client(player, ProtoDef.NotifyTaskReset.name, {})
    -- tasksystem.updateProcess(player, pid, define.taskType.makeEquip, {1}, define.taskValType.add, {1,1,1,1010101})
    -- tasksystem.updateProcess(player, pid, define.taskType.sellEquipCnt, {1}, define.taskValType.add, {1,1,1,1010101})
    -- tasksystem.updateProcess(player, pid, define.taskType.recruit, {1}, define.taskValType.add)
    -- tasksystem.updateProcess(player, pid, define.taskType.collectCnt, {1}, define.taskValType.add)
end

local function jumptask(player, pid, args) -- jumptask 3 20006 1
    -- player = gPlayerMgr:getPlayerById(3518438940135752557)
    local datas = getData(player)
    if not datas then
        print("jumptask no datas", pid)
        return
    end

    local list = datas.list
    if not list then
        print("jumptask no list", pid)
        return
    end
    pid = player:getPid()
    local type = args[1]
    local id = args[2]
    local wheel = args[3]
    local stype = tostring(type)
    local typeData = list[stype]
    if not typeData then
        print("jumptask no typeData", pid, stype)
        return
    end

    --typeData.task = {}

    local task = typeData.task
    for k, v in pairs(taskTypeConfig) do
        local ok = false
        if v.kind == type and type == define.taskTypeDef.daily and k < id and wheel == v.index or 
        v.kind == type and type == define.taskTypeDef.newPerson and k < id or 
        v.kind == type and type == define.taskTypeDef.chapter and
            k < id and wheel == v.index then
            ok = true
        end
        if ok then
            local sk = tostring(k)
            task[sk] = {
                state = define.taskRewardDef.noRecv,
                progress = v.progress
            }
        end
    end

    saveData(player)
    ReqTaskInfo(player)
end

local function UpdateTaskProcess(player, pid, taskType, val, addType, cond, notice, args)
    tasksystem.updateProcess(player, pid, taskType, val, addType, cond, notice, args)
end

_G.gluaFuncUpdateTaskProcess = UpdateTaskProcess

gm.reg("jumptask", jumptask) -- jumptask 1 14
gm.reg("gmShowTaskInfo", gmShowTaskInfo)
gm.reg("gmLogin", gmLogin)
gm.reg("f333", f333)
gm.reg("f44", f44)
event.reg(event.eventType.login, login)
event.reg(event.eventType.newDay, newDay)

net.regMessage(ProtoDef.ReqTaskInfo.id, ReqTaskInfo, net.messType.gate)
net.regMessage(ProtoDef.ReqRecvTaskRd.id, ReqRecvTaskRd, net.messType.gate)

return tasksystem
