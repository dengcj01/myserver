


-- 服务器事件定义
ServerEventDefine =
{
    serverMinute = 1, -- 服务器每分钟执行
    login = 2, -- 玩家登入
    logout = 3, -- 玩家退出
    newDay = 4, -- 服务器0点跨天
    start=5, -- 服务器启动
    additem = 6, -- 获得道具
}



serverEventMgr = {event = {}}


function serverEventMgr.reg(eid, func)
    if type(func) ~= "function" then
        printTrace("serverEventMgr.reg err", eid, func)
        return
    end

    serverEventMgr.event[eid] = serverEventMgr.event[eid] or {}
    local list = serverEventMgr.event[eid]
    table.insert(list, func)
end


function gServerUpdate(curTime)
    toolsMgr.luaGc(curTime)
    
    if _G.__nextMinTime == nil then
        local strtime = os.date("%Y%m%d%H%M%S", curTime) -- 20231008143446
        local sec = tonumber(string.sub(strtime, -2, -1)) 
        if sec == 0 then
            __nextMinTime = curTime + 60
        else
            __nextMinTime = curTime + 60 - sec
        end
    end

    local playerList = gPlayerMgr:getOnlinePlayers()
    if curTime >= __nextMinTime then
        local event = serverEventMgr.event
        local list = event[ServerEventDefine.serverMinute] or {}
        for k, v in pairs(list) do
            toolsMgr.safeCall(v, curTime, playerList)
        end
        __nextMinTime = curTime + 60
    end


    if curTime < __nextDayTime then
        return
    end


    __nextDayTime = __nextDayTime + 86400
    local event = serverEventMgr.event
    local list = event[ServerEventDefine.newDay] or {}

    local zeroList = gPlayerMgr:getZeroList()
    for _, player in pairs(playerList) do
        for _, v in pairs(list) do
            if not zeroList[player:getPid()] then 
                toolsMgr.safeCall(v, player, curTime)
            end
        end
    end
    gPlayerMgr:cleanZeroList()
end


function gServerCmd(player, cmd)
    local args = toolsMgr.split(cmd)
    local args1 = args[1]
    local cmd = args1
    local func = cmd



    local s, _ = string.find(args1, "@")

    if s ~= nil then
        local pos = string.find(cmd," ")
        if pos then
            cmd = string.sub(cmd, 2, pos-1)
        else
            cmd = string.sub(cmd, 2, -1) 
        end
    end


    func = gmMgr[cmd]
    if not func then
        func = gmMgr.gmlist[cmd]
    end

    local param = {}
    for i=2,#args do
        table.insert(param, tonumber(args[i]))
    end

    toolsMgr.ss(param, "gm参数是")

    if type(func) == "function" then
        local pid = 0
        if player and type(player) == "userdata" then
            pid = player:getPid()
        end
        func(player, pid, param)
        print(string.format("----------------执行gm指令 %s 结束 ----------------", cmd))
    else
        print("----------------未找到这个gm指令----------------", cmd)
    end
end

function gNewDay(player, curTime)
    local event = serverEventMgr.event
    local list = event[ServerEventDefine.newDay] or {}
    for k, v in pairs(list) do
        toolsMgr.safeCall(v, player, curTime)
    end
end

function gLogin(player, isfirst, curTime)
    local event = serverEventMgr.event
    local list = event[ServerEventDefine.login] or {}
    for k, v in pairs(list) do
        toolsMgr.safeCall(v, player, isfirst, curTime)
    end
end

function gLogout(player, curTime)
    local event = serverEventMgr.event
    local list = event[ServerEventDefine.logout] or {}
    for k, v in pairs(list) do
        toolsMgr.safeCall(v, player, curTime)
    end
end

function gServerStart()
    local event = serverEventMgr.event
    local list = event[ServerEventDefine.start] or {}
    for k, v in pairs(list) do
        toolsMgr.safeCall(v)
    end
end

function gTriggerAddItemEvent(player, itemId, count)
    local event = serverEventMgr.event
    local list = event[ServerEventDefine.additem] or {}
    for k, v in pairs(list) do
        toolsMgr.safeCall(player, itemId, count)
    end
end
