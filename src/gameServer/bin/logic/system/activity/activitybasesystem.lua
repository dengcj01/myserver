
local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"

local playermoduledata = require "common.playermoduledata"

local activitytimeConfig = require "logic.config.activitytimeConfig"
local activitytimeGMConfig = require "logic.config.activitytimeGMConfig"
local sevenDailyRewardConfig = require "logic.config.sevenDailyRewardConfig"
local eightLogRewardConfig = require "logic.config.eightLogRewardConfig"
local mailsConfig = require "logic.config.mailsConfig"


local activitybasesystem = {}

local activeActingList  = _G.activeActingList  -- 已运行的活动
local normalActiveConf = _G.normalActiveConf -- 非创角类活动
local playerActiveConf = _G.normalActiveConf -- 创角活动配置


-- 活动时间类型定义
local ActiveTimeType = {
    openTime = 1, -- 开服时间
    realTime = 2, -- 具体时间
    weekDay = 3, -- 按周几开
    createTime = 4, -- 创角时间
}

local activityTypeList = {
    event = {},

}

-- 活动需要做的任务id缓存
local cacheActivityTaskIds = {}
-- 活动需要做任务的活动id缓存
local cacheActivityIds = {}

for k, v in pairs(activitytimeConfig) do
    local actType = v.activity_type
    if actType == define.activeTypeDefine.sevenTask then
        local conf = sevenDailyRewardConfig[v.sheetId]
        if conf then
            for _, dayConf in pairs(conf.days or {}) do
                for _, id in pairs(dayConf.task_id or {}) do
                    cacheActivityTaskIds[id] = 1
                end
            end
            cacheActivityIds[actType] = cacheActivityIds[actType] or {}
            local tab = cacheActivityIds[actType]
            table.insert(tab, k)
        end
    end
end

for k, v in pairs(activitytimeGMConfig) do
    local actType = v.activity_type
    cacheActivityIds[actType] = cacheActivityIds[actType] or {}
    local tab = cacheActivityIds[actType]
    table.insert(tab, k)
end

function activitybasesystem.getCacheTaskId()
    return cacheActivityTaskIds
end

function activitybasesystem.getCacheId(actType)
    return cacheActivityIds[actType]
end

function activitybasesystem.reg(func, actType, eid)
    if type(func) ~= "function" then
        printTrace("activitybasesystem.reg err", func, actType, eid)
        return
    end

    activityTypeList.event[eid] = activityTypeList.event[eid] or {}
    local elist = activityTypeList.event[eid]

    elist[actType] = func
end




local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.activity)
end

function activitybasesystem.saveData(player)
    return playermoduledata.saveData(player, define.playerModuleDefine.activity)
end




function activitybasesystem.getData(player, activeId)
    local datas = getData(player)
    if not datas then
        print("activitybasesystem.getData no datas", player:getPid())
        return
    end

    local activeId = tostring(activeId)
    local data = datas[activeId]
    if not data then
        return
    end

    return data.data
end

function activitybasesystem.getConfig(id, actType)
    id = tonumber(id)
    local cfg = activitytimeConfig[id]
    if not cfg then
        cfg = activitytimeGMConfig[id]
    end

    if not cfg then
        return
    end

    local conf = nil
    local idx = cfg.sheetId
    if actType == define.activeTypeDefine.sevenTask then
        conf = sevenDailyRewardConfig[idx]
    elseif actType == define.activeTypeDefine.eightSign then
        conf = eightLogRewardConfig[idx]
    elseif actType == define.activeTypeDefine.mail then
        conf = mailsConfig[idx]
    end

    return conf
end


local function ReqActiveData(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqActiveData no datas", pid)
        return
    end

    local msgs = {data = {}}
    local data = msgs.data
    for k, v in pairs(datas) do
        local info = {}
        info.id = tonumber(k)
        info.type = v.type
        info.startTime = v.startTime
        info.endTime = v.endTime
        table.insert(data, info)
    end

    --tools.ss(msgs)
    net.sendMsg2Client(player, ProtoDef.ResActiveData.name, msgs)
end



local function loadConfig(config)
    for id, v in pairs(config) do
        if v.date_type == ActiveTimeType.createTime then
            playerActiveConf[id] = v
        else
            normalActiveConf[id] = v
        end
    end
end

local function checkActiveAct(curTime)
    local curTime = curTime or gTools:getNowTime()
    local zeroTime = gTools:get0Time(curTime)
    local openServerTimer = __oepnServerTime
    local nowWeek = gTools:getDayOfWeek(curTime)

    for k, v in pairs(normalActiveConf) do
        if activeActingList[k] == nil and v.activity_switch == 1 then
            local ok = false
            repeat
                local stime, etime = nil, nil
                if v.date_type == ActiveTimeType.realTime then
                    local startTime = v.starttime

                    local startInfo = v.date[1]
                    local syear = startInfo[1]
                    local smonth = startInfo[2]
                    local sday = startInfo[3]

                    stime = gTools:get0Time(gTools:getNowTimeByDate(syear, smonth, sday, 0, 0, 0))

                    local endInfo = v.date[2]

                    local eyear = endInfo[1]
                    local emonth = endInfo[2]
                    local eday = endInfo[3]

                    etime = gTools:get0Time(gTools:getNowTimeByDate(eyear, emonth, eday, 0, 0, 0))

                    if stime and etime and stime >= etime then
                        print("运营活动配置错误", k, gTools:timestampToString(stime), gTools:timestampToString(etime))
                        break
                    end

                    if curTime >= stime and curTime < etime then
                        ok = true
                    end
                elseif v.date_type == ActiveTimeType.openTime then
                    local timeInfo = v.date
                    local sday = timeInfo[1]
                    local eday = timeInfo[2]
                    if eday < eday then
                        print("运营活动配置错误", k, sday, eday)
                        break
                    end


                    stime = openServerTimer + (sday - 1) * 86400
                    etime = openServerTimer + eday * 86400

                    --print("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",stime,etime)

                    if curTime >= stime and curTime < etime then
                        ok = true
                    end
                elseif v.date_type == ActiveTimeType.weekDay then
                    if tools.isInArr(v.date, nowWeek) then
                        stime = zeroTime
                        etime = zeroTime + 86400
                        ok = true
                    end
                end

                if ok then
                    activeActingList[k] = {
                        startTime = stime,
                        endTime = etime,
                        type = v.activity_type,
                        stime = gTools:timestampToString(stime),
                        etime = gTools:timestampToString(etime),
                    }
                end
            until true
        end
    end
end

local function processPlayerActiveEnd(player, pid, curTime, isForce)
    local datas = getData(player)
    if not datas then
        return
    end


    local closeList = {}

    for k, v in pairs(datas) do
        local endTime = v.endTime
        local id = tonumber(k)
        local cfg = activitytimeConfig[id]
        if not cfg then
            cfg = activitytimeGMConfig[id] or {}
        end

        local state = cfg.activity_switch or 0
        if (endTime and curTime >= endTime) or isForce or state == 0 then

            table.insert(closeList, {id = id})
        end
    end

    local elist = activityTypeList.event[define.activeEventDefine.close] or {}

    for k, v in pairs(closeList) do
        local id = tostring(v.id)
        local data = datas[id]
        local type = data.type
        local func = elist[type]

        local mdata = data.data

        if func and mdata and next(mdata) then
            tools.safeCall(func, player, pid, id, type, mdata)
        end

        datas[id] = nil
    end

    return closeList
end

local function addNewAct(player, datas, id, info, openList)
    local id = tostring(id)
    if datas[id] == nil then
        local type = info.type
        local stime = info.startTime
        local etime = info.endTime

        datas[id] = {
            startTime = stime,
            endTime = etime,
            type = type,
            data = {},
        }


        table.insert(openList, {
            id = tonumber(id),
            type = type,
            startTime = stime,
            endTime = etime,
        })
    end

end

local function processPlayerActiveStart(player, pid, curTime)
    local datas = getData(player)
    if not datas then
        return
    end

    curTime = curTime or gTools:getNowTime()

    local openList = {}
    for k, v in pairs(activeActingList) do
        addNewAct(player, datas, k, v, openList)
    end

    local createTime = gTools:get0Time(player:getCreateTime()) -- 处理创角类型活动


    for k, v in pairs(playerActiveConf) do
        local sk = tostring(k)
        if datas[sk] == nil and v.activity_switch == 1 and v.date_type == ActiveTimeType.createTime then
            local closeday = v.date[2]
            local startday = v.date[1]
            if closeday >= startday then
                local stime = createTime + (startday - 1) * 86400
                local etime = createTime + closeday * 86400

                if curTime >= stime and curTime < etime then
                    local info = {
                        type = v.activity_type,
                        startTime = stime,
                        endTime = etime,
                    }

                    addNewAct(player, datas, sk, info, openList)
                end
            end
        end
    end

    local elist = activityTypeList.event[define.activeEventDefine.open] or {}

    for k, v in pairs(openList) do
        local id = tostring(v.id)
        local data = datas[id]
        local type = data.type
        local func = elist[type]
        local mdata = data.data
        if func then
            tools.safeCall(func, player, pid, id, type, mdata)
        end
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

        --tools.ss(msgs)
        net.sendMsg2Client(player, ProtoDef.NotifyOptActive.name, msgs)
    end
end

local function update(curTime, playerList)
    checkActiveAct(curTime)

    for k, v in pairs(activeActingList) do
        if curTime >= v.endTime then
            activeActingList[k] = nil
        end
    end


    for pid, player in pairs(playerList) do
        local closeList = processPlayerActiveEnd(player, pid, curTime)
        local openList = processPlayerActiveStart(player, pid, curTime)


        -- tools.ss(closeList, "关闭的活动id")
        -- tools.ss(openList, "开启的活动id")

        openOrCloseAct(player, closeList, define.activeEventDefine.close)
        openOrCloseAct(player, openList, define.activeEventDefine.open)

        if next(closeList) or next(openList) then
            activitybasesystem.saveData(player)
        end
    end



end




local function oneKeyDelBga(player, pid, args)
    local players = gPlayerMgr:getOnlinePlayers()
    local curTime = gTools:getNowTime()
    for pid, player in pairs(players) do
        local list = processPlayerActiveEnd(player, pid, curTime, true)
        activitybasesystem.saveData(player)
        openOrCloseAct(player, list, define.activeEventDefine.close)
    end
end

local function oneKeyBga(player, pid, args)
    oneKeyDelBga(player, pid, args)
    playerActiveConf = {}
    normalActiveConf = {}
    activeActingList = {}

    loadConfig(activitytimeGMConfig)
    checkActiveAct()

    local players = gPlayerMgr:getOnlinePlayers()
    local curTime = gTools:getNowTime()
    for pid, player in pairs(players) do
        local list = processPlayerActiveStart(player, pid, curTime)
        openOrCloseAct(player, list, define.activeEventDefine.open)


        activitybasesystem.saveData(player)
        
    end
    
end

local function reloadBga(player, pid, args)
    loadConfig(activitytimeGMConfig)
    checkActiveAct()
end

local function serverStart()
    loadConfig(activitytimeConfig)
    checkActiveAct()
end

local function showact(player, pid, args)
    tools.ss(activeActingList)
end

-- 获取同类型的所有活动id
function activitybasesystem.getSameTypeActivityIdList(player, actType)
    local datas = getData(player)
    local ret = {}
    for k, v in pairs(datas or {}) do
        if v.type == actType then
            table.insert(ret, tonumber(k))
        end
    end
    return ret
end


local function login(player, pid, curTime, isfirst)

    local closeList = processPlayerActiveEnd(player, pid, curTime)
    local openList = processPlayerActiveStart(player, pid, curTime)

    if next(closeList) or next(openList) then
        activitybasesystem.saveData(player)
    end
end

local function loadbga(player, pid, args)
    playerActiveConf = {}
    normalActiveConf = {}
    activeActingList = {}
    serverStart()

    local players = gPlayerMgr:getOnlinePlayers()
    local curTime = gTools:getNowTime()
    for pid, player in pairs(players) do
        local closeList = processPlayerActiveEnd(player, pid, curTime)
        local openList = processPlayerActiveStart(player, pid, curTime)
        openOrCloseAct(player, closeList, define.activeEventDefine.close)
        openOrCloseAct(player, openList, define.activeEventDefine.open)
        activitybasesystem.saveData(player)
    end
    
end


local function resetactive(player, pid, args)
    serverStart()
    showact()
end

local function showact1(player, pid, args)
    player = gPlayerMgr:getPlayerById(283204899630523)
    tools.ss(getData(player))

end

local function setactplayertime(player, pid, args)
    player = gPlayerMgr:getPlayerById(283204570741235)
    local datas = getData(player)
    local data = datas["4"]
    data.endTime = 1729267200
    activitybasesystem.saveData(player)
end

local function showcacheActivityTaskIds(player, pid, args)
   tools.ss(cacheActivityTaskIds) 
end

local function showactiveActingList(player, pid, args)
    tools.ss(activeActingList) 
end


gm.reg("oneKeyBga", oneKeyBga)
gm.reg("loadbga", loadbga)
gm.reg("oneKeyDelBga", oneKeyDelBga)
gm.reg("showact", showact)
gm.reg("resetactive", resetactive)
gm.reg("showact1", showact1)
gm.reg("showcacheActivityTaskIds", showcacheActivityTaskIds)


event.reg(event.eventType.start, serverStart)
event.reg(event.eventType.serverMinute, update)
event.reg(event.eventType.login, login)

net.regMessage(ProtoDef.ReqActiveData.id, ReqActiveData, net.messType.gate)




return activitybasesystem


