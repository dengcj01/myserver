
local tools = require "common.tools"
local gm = require "common.gm"




local event = 
{
    -- 服务器事件定义
    eventType =
    {
        serverMinute = 1, -- 服务器每分钟执行
        login = 2, -- 玩家登入
        logout = 3, -- 玩家退出
        newDay = 4, -- 服务器0点跨天
        start=5, -- 服务器启动
        playerLevel = 6, --玩家等级变化
        charge=7, -- 玩家充值
        new4Day = 8, -- 服务器凌晨4点跨天
    },
    eventList = {},

    -- 后台命令事件定义
    optType = 
    {
        mail = 1, --邮件
        player = 2, -- 玩家操作
        system = 3,--系统公告,跑马灯
        charge = 4, -- 充值
        cdkey = 5, -- 兑换码
    }, 

    httpEventList = {}
}

event.httpEvent = 
{
    
    [event.optType.mail] = 
    {
        addMail = 1,        --邮件
    },
    [event.optType.system] = 
    {
        systemNotice = 0,   
    },
    [event.optType.player] = 
    {
        forbidden=2,              --禁言
        ban = 3,                   -- 封号
        kick = 4,                   -- 踢人
        costItem = 5,   -- 扣物品
    },
    [event.optType.cdkey] = 
    {
        cdkey = 1,        --兑换码
    },
    [event.optType.charge] =
    {
        charge = 1, -- 充值
    }
}



function event.reg(eid, func, chargeType)
    if type(func) ~= "function" then
        printTrace("event.reg err", eid, func)
        return
    end

    event.eventList[eid] = event.eventList[eid] or {}
    local eventList = event.eventList[eid]
    if eid == event.eventType.charge then
        eventList[chargeType] = func
    else
        table.insert(eventList, func)
    end


end

function event.regHttp(optType, eid, func)
    if type(func) ~= "function" then
        printTrace("event.regHttp", optType, eid, func)
        return
    end

    event.httpEventList[optType] = event.httpEventList[optType] or {}
    local list = event.httpEventList[optType]
    list[eid] = func


end

function gPlayerLevelChange(player, pid, oldLevel, nowLevel)
    local eventList = event.eventList
    local list = eventList[event.eventType.playerLevel] or {}
    for k, v in pairs(list) do
        tools.safeCall(v, player, pid, oldLevel, nowLevel)
    end
end


function gServerUpdate(curTime)

    tools.luaGc(curTime)



    local playerList = gPlayerMgr:getOnlinePlayers()
    local eventList = event.eventList
    local list = eventList[event.eventType.serverMinute] or {}
    for k, v in pairs(list) do
        tools.safeCall(v, curTime, playerList)
    end


    if curTime >= __nextDayTime then
        print("-----------------------server new day------------------", curTime, __nextDayTime)
        __nextDayTime = __nextDayTime + 86400
    end

    if curTime >= __nextNewDayTime then
        __nextNewDayTime = __nextDayTime + 14400
        local eventList = event.eventList
        local list = eventList[event.eventType.newDay] or {}
    

        for pid, player in pairs(playerList) do
            for _, v in pairs(list) do
                if not player:isZeroTimeLogin() then
                    tools.safeCall(v, player, pid, curTime, true)
                end
            end
        end


        list = eventList[event.eventType.new4Day] or {}
        for _, v in pairs(list) do
            tools.safeCall(v, curTime)
        end
    end
end

local function processCmd(player, pid, cmd, args)
    local func = cmd
    func = gm[cmd]
    if not func then
        func = gm.list[cmd]
    end

    local param = {}
    for i=2,#args do
        table.insert(param, tonumber(args[i]))
    end

    tools.ss(param, "gm参数是")

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

function gServerCmd(player, cmd)
    local args = tools.split(cmd)
    local args1 = args[1]
    local cmd = args1
    --local func = cmd


    local s, _ = string.find(args1, "@")

    if s ~= nil then
        local pos = string.find(cmd," ")
        if pos then
            cmd = string.sub(cmd, 2, pos-1)
        else
            cmd = string.sub(cmd, 2, -1) 
        end
    end


    processCmd(player, 0, cmd, args)

end

function gNewDay(player, pid, curTime)
    local eventList = event.eventList
    local list = eventList[event.eventType.newDay] or {}
    for k, v in pairs(list) do
        tools.safeCall(v, player, pid, curTime, false)
    end
end

function gLogin(player, pid, curTime, isfirst)
    local eventList = event.eventList
    local list = eventList[event.eventType.login] or {}
    for k, v in pairs(list) do
        tools.safeCall(v, player, pid, curTime, isfirst)
    end
end

function gLogout(player, pid, curTime)
    local eventList = event.eventList
    local list = eventList[event.eventType.logout] or {}
    for k, v in pairs(list) do
        tools.safeCall(v, player, pid, curTime)
    end
end

function gServerStart()
    local eventList = event.eventList
    local list = eventList[event.eventType.start] or {}
    for k, v in pairs(list) do
        tools.safeCall(v)
    end
end

function gProcessHttp(player, cmd)
    --print("gProcessHttp", cmd)
    local data = tools.decode(cmd)

    print("后台发送送数据")
    tools.ss(data)


    
    local etype = tonumber(data.type)
    local func = nil
    if etype == event.optType.mail then -- 邮件
        func = event.httpEventList[etype][etype]
    elseif etype == event.optType.player then -- 玩家操作
        local act = data.cmd.action
        func = event.httpEventList[etype][act]
    elseif etype == event.optType.system then -- 系统公告
        func = event.httpEventList[etype][event.httpEvent[etype].systemNotice]
    elseif etype == event.optType.cdkey then -- cdkey
        func = event.httpEventList[etype][event.httpEvent[etype].cdkey]
    elseif etype == event.optType.charge then -- 充值
        func = event.httpEventList[etype][event.httpEvent[etype].charge]
    end


    if not func then
        print("gProcessHttp no find func")
        return
    end

    func(data.cmd)
end

_G.gluaFuncprocessCmd = processCmd

return event