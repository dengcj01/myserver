local activeActingList = {} -- 已运行的活动
local normalActiveConf = {} -- 非创角类活动
local playerActiveConf = {} -- 创角活动配置

-- 活动事件定义
ActiveEventDefine = {
    open = 1, -- 活动开启
    close = 2 -- 活动关闭
}

-- 活动时间类型定义
local ActiveTimeType = {
    realTime = 0, -- 具体时间
    openTime = 1, -- 开服时间
    createTime = 2, -- 创角时间
    megerTime = 3 -- 合服时间
}

activeMgr = {
    event = {},
    cfg = {}
} -- 活动事件列表

function activeMgr.regEvent(func, type, eid)
    if type(func) ~= "function" then
        printTrace("activeMgr.regEvent err", func, type, eid)
        return
    end

    activeMgr.event[eid] = activeMgr.event[eid] or {}
    local elist = activeMgr.event[eid]

    elist[type] = func
end

function activeMgr.regCfg(func, type)
    if type(func) ~= "function" then
        printTrace("regCfg.regCfg err", func, type)
        return
    end

    activeMgr.cfg[type] = func
end

function activeMgr.getConf(player, id, type, cfgIdx, config)
    local conf = config[cfgIdx]
    if not conf then
        print("activeMgr.getConf no conf", type, config)
        return
    end

    return conf.con
end

local function getData(player)
    return playerModuleDataMgr.getData(player, PlayerModuleDefine.activities)
end

local function saveData(player)
    return playerModuleDataMgr.saveData(player, PlayerModuleDefine.activities)
end

local function loadConfig(config)
    for k, v in pairs(config) do
        local id = v.uid
        if v.activitytimetype == ActiveTimeType.createTime and playerActiveConf[id] == nil then
            playerActiveConf[id] = v
        elseif v.activitytimetype ~= ActiveTimeType.createTime and normalActiveConf[id] == nil then
            normalActiveConf[id] = v
        end
    end
end

local function checkActiveAct(curTime)
    local curTime = curTime or os.time()

    for k, v in pairs(normalActiveConf) do
        if activeActingList[k] == nil and v.state == 1 then
            local ok = false
            repeat
                local stime, etime = nil, nil
                if v.activitytimetype == ActiveTimeType.realTime then
                    local startTime = v.starttime

                    local syear = tonumber(string.sub(startTime, 1, 4))
                    local smonth = tonumber(string.sub(startTime, 6, 7))
                    local sday = tonumber(string.sub(startTime, 9, 10))

                    stime = gTools:get0Time(os.time({
                        year = syear,
                        month = smonth,
                        day = sday,
                        hour = 0,
                        min = 0,
                        sec = 0
                    }))

                    local endTime = v.closetime

                    local eyear = tonumber(string.sub(endTime, 1, 4))
                    local emonth = tonumber(string.sub(endTime, 6, 7))
                    local eday = tonumber(string.sub(endTime, 9, 10))

                    etime = gTools:get0Time(os.time({
                        year = eyear,
                        month = emonth,
                        day = eday,
                        hour = 0,
                        min = 0,
                        sec = 0
                    }))

                    if stime and etime and stime >= etime then
                        print("load activities err", k, os.date("%Y-%m-%d %H:%M:%S", startTime),
                            os.date("%Y-%m-%d %H:%M:%S", etime))
                        break
                    end

                    if curTime >= stime and curTime < etime then
                        ok = true
                    end
                elseif v.activitytimetype == ActiveTimeType.openTime then
                    if v.closeday < v.startday then
                        print("load activities err1", k, v.startday, v.closeday)
                        break
                    end

                    local openServerTimer = __oepnServerTime
                    stime = openServerTimer + (v.startday - 1) * 86400
                    etime = openServerTimer + v.closeday * 86400

                    if curTime >= stime and curTime < etime then
                        ok = true
                    end
                elseif v.activitytimetype == ActiveTimeType.megerTime then
                end

                if ok then
                    activeActingList[k] = {
                        startTime = stime,
                        endTime = etime,
                        param = v.activityparam,
                        type = v.activitytype
                    }
                end
            until true
        end
    end
end

local function processPlayerActiveEnd(player, curTime, isForce)
    local datas = getData(player)
    if not datas then
        return
    end

    local endList = {}
    local closeList = nil

    for k, v in pairs(datas) do
        if (v.endTime and curTime >= v.endTime) or isForce then
            local type = v.type
            local id = v.id

            endList[type] = endList[type] or {}
            local list = endList[type]

            table.insert(list, id)

            closeList = closeList or {}
            table.insert(closeList, id)
        end
    end

    local elist = activeMgr.event[ActiveEventDefine.close] or {}

    for actType, idlist in pairs(endList) do
        local func = elist[actType]
        if func then
            for _, actId in ipairs(idlist) do
                local sid = tostring(actId)
                local data = datas[sid]
                if data and data.data then
                    toolsMgr.safeCall(func, player, actId, actType, data.data)
                end

                datas[sid] = nil
            end
        end
    end

    return closeList
end

local function addNewAct(player, datas, id, info, startList, openList)
    if datas[id] == nil then
        local type = info.type
        local stime = info.startTime
        local etime = info.endTime
        local param = info.param

        datas[id] = {
            startTime = stime,
            endTime = etime,
            param = param,
            type = type
        }

        startList[type] = startList[type] or {}

        table.insert(startList[type], id)

        table.insert(openList, {
            id = tonumber(id),
            type = type,
            startTime = stime,
            endTime = etime,
            param = param
        })
    end

end

local function processPlayerActiveStart(player, curTime)
    local datas = getData(player)
    if not datas then
        return
    end

    curTime = curTime or os.time()

    local startList = {}
    local openList = {}
    for k, v in pairs(activeActingList) do
        local sk = tostring(k)
        addNewAct(player, datas, sk, v, startList, openList)
    end

    local createTime = gTools:get0Time(player:getCreateTime()) -- 处理创角类型活动

    for k, v in pairs(playerActiveConf) do
        local sk = tostring(k)
        if datas[sk] == nil and v.state == 1 and v.activitytimetype == ActiveTimeType.createTime then
            if v.closeday >= v.startday then
                local stime = createTime + (v.startday - 1) * 86400
                local etime = createTime + v.closeday * 86400

                if curTime >= stime and curTime < etime then
                    local info = {
                        type = v.activitytype,
                        startTime = stime,
                        endTime = etime,
                        param = v.activityparam
                    }

                    addNewAct(player, datas, sk, info, startList, openList)
                end
            end
        end
    end

    local elist = activeMgr.event[ActiveEventDefine.open] or {}

    for actType, idlist in pairs(startList) do
        local func = elist[actType]
        if func then
            for _, actId in ipairs(idlist) do
                local sid = tostring(actId)
                datas[sid] = datas[sid] or {}
                local data = datas[sid]
                data.data = {}
                toolsMgr.safeCall(func, player, actId, actType, data.startTime, data.data)
            end
        end
    end

    if next(openList) == nil then
        return
    end

    return openList
end

local function openOrCloseAct(player, list, opt)
    list = list or {}
    if next(list) then
        local msgs = {
            opt = opt
        }
        msgs.data = list
        sendMsg2Client(player, "ServerNoticeOptActive", msgs)
    end
end

local function update(curTime, playerList)
    checkActiveAct(curTime)

    for k, v in pairs(activeActingList) do
        if curTime >= v.endTime then
            activeActingList[k] = nil
        end
    end

    for _, player in pairs(playerList) do
        local closeList = processPlayerActiveEnd(player, curTime)
        local openList = processPlayerActiveStart(player, curTime)

        openOrCloseAct(player, closeList, ActiveEventDefine.close)
        openOrCloseAct(player, openList, ActiveEventDefine.open)

        if closeList or openList then
            saveData(player)
        end
    end

end

local function loadBga(player, pid, args)

end

local function oneKeyDelBga(player, pid, args)
    local players = gPlayerMgr:getOnlinePlayers()

    for _, player in pairs(players) do
        local list = processPlayerActiveEnd(player, nil, true)
        saveData(player)
        openOrCloseAct(player, list, ActiveEventDefine.close)
    end

end

local function oneKeyBga(player, pid, args)
    oneKeyDelBga(player, pid, args)
    playerActiveConf = {}
    normalActiveConf = {}
    activeActingList = {}

    loadConfig(autoOpenActivitiesCfgs)
    checkActiveAct()

    local players = gPlayerMgr:getOnlinePlayers()

    for _, player in pairs(players) do
        local list = processPlayerActiveStart(player)
        openOrCloseAct(player, list, ActiveEventDefine.open)
        saveData(player)
    end

end

local function serverStart()
    loadConfig(activities)
    checkActiveAct()
end

local function showact(player, pid, args)
    toolsMgr.ss(activeActingList)
end

local function ReqActiveData(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqActiveData no datas", pid)
        return
    end

    local msgs = {
        data = {}
    }
    for k, v in pairs(datas) do
        local info = {
            id = tonumber(k),
            type = v.type,
            param = v.param,
            startTime = v.startTime,
            endTime = v.endTime
        }
        table.insert(msgs.data, info)
    end

    sendMsg2Client(player, ProtoDef.ResActiveData.name, msgs)
end

local function ReqActiveConf(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqActiveConf no datas", pid)
        return
    end

    local id = proto.id
    local data = datas[tostring(id)]
    if not data then
        print("ReqActiveConf no data", pid)
        return
    end

    local type = data.type
    local func = activeMgr.cfg[type]
    if not func then
        print("ReqActiveConf no func", pid, type)
        return
    end

    local param = data.param
    if not param then
        print("ReqActiveConf no param", pid, type)
        return
    end

    param = toolsMgr.decode(param)
    if param == nil then
        print("ReqActiveConf param err", pid, id)
        return
    end

    local config = param.config
    if not config then
        print("ReqActiveConf no config", pid, type)
        return
    end

    local cfg = toolsMgr.safeCall(func, player, id, type, config)
    if not cfg then
        print("ReqActiveConf no cfg", pid, data.type)
        return
    end

    local msgs = {
        id = id
    }
    msgs.data = toolsMgr.encode(cfg)

    sendMsg2Client(player, ProtoDef.ReqActiveConf.name, msgs)

end

local function login(player, isfirst, curTime, isNewDay)
    local closeList = processPlayerActiveEnd(player, curTime)
    local openList = processPlayerActiveStart(player, curTime)

    if closeList or openList then
        saveData(player)
    end
end

gmMgr.reg("loadBga", loadBga)
gmMgr.reg("oneKeyBga", oneKeyBga)
gmMgr.reg("oneKeyDelBga", oneKeyDelBga)
gmMgr.reg("showact", showact)

serverEventMgr.reg(ServerEventDefine.start, serverStart)
serverEventMgr.reg(ServerEventDefine.serverMinute, update)
serverEventMgr.reg(ServerEventDefine.login, login)

netMgr.regMessage(ProtoDef.ReqActiveData.id, ReqActiveData, netMgr.messType.gate)
netMgr.regMessage(ProtoDef.ReqActiveConf.id, ReqActiveConf, netMgr.messType.gate)

