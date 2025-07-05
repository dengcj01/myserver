

local tools = require "common.tools"
local event = require "common.event"

local timerMgr = 
{
    timerArgsList = {}
}

function gTimerCallBack(player, eid, timerc)
    local pid = player:getPid()
    local datas = timerMgr.timerArgsList[pid]
    if not datas then
        print("timeCallBack no datas", pid)
        return
    end


    local data = datas[eid]
    if not data then
        print("timeCallBack no data", pid, eid)
        return
    end

    tools.safeCall(data.func, player, table.unpack(data.args))
    if timerc == 0 then
        datas[eid] = nil
        if next(datas) == nil then
            timerMgr.timerArgsList[pid] = nil
        end
    end


end


function timerMgr.addTimer(player, expire, func, opt, ...)
    if not player or type(player) ~= "userdata" or type(func) ~= "function" then
        print("timerMgr.addTimer err", player, expire, func, opt)
        return
    end

    local pid = player:getPid()
    opt = opt or 0
    
    local eid = gTimer:add(expire, "gTimerCallBack", pid, opt)
    if string.len(eid) > 0 then

        timerMgr.timerArgsList[pid] = timerMgr.timerArgsList[pid] or {}
        local datas = timerMgr.timerArgsList[pid]
        datas[eid] = {args = table.pack(...), func = func}

        return eid
    end
end


function timerMgr.delTimer(pid, eid)
    if type(eid) ~= "string" then
        print("timerMgr.delTimer err", pid, eid)
        return
    end

    local datas = timerMgr.timerArgsList[pid]
    if not datas then
        print("timerMgr.delTimer no datas", pid)
        return
    end

    datas[eid] = nil

    gTimer:del(eid)

end

local function logout(player, pid, curTime)
    local datas = timerMgr.timerArgsList[pid] or {}
    for k, v in pairs(datas) do
        gTimer:del(k)
    end

    timerMgr.timerArgsList[pid] = nil
end

event.reg(event.eventType.logout, logout)

return timerMgr
