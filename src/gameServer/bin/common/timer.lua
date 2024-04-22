
_G.TimerArgsList = _G.TimerArgsList or {}

timerMgr = {}

function gTimerCallBack(player, eid, timerc)
    local pid = player:getPid()
    local datas = TimerArgsList[pid]
    if not datas then
        print("timeCallBack no datas", pid)
        return
    end


    local data = datas[eid]
    if not data then
        print("timeCallBack no data", pid, eid)
        return
    end

    toolsMgr.safeCall(data.func, player, table.unpack(data.args))
    if timerc == 0 then
        datas[eid] = nil
        if next(datas) == nil then
            TimerArgsList[pid] = nil
        end
    end


end

-- 注意事项:回调函数的参数列表不要直接传递某个table值,不然热更新是更新不到的.如传递配置的key对应的table,这table热更新后还是旧值.正确使用是尽量通过key去索引
function timerMgr.addTimer(player, expire, func, opt, ...)
    if not player or type(player) ~= "userdata" or type(func) ~= "function" then
        print("timerMgr.addTimer err", player, expire, func, opt)
        return
    end

    local pid = player:getPid()
    opt = opt or 0
    
    local eid = gTimer:add(expire, "gTimerCallBack", pid, opt)
    if string.len(eid) > 0 then

        TimerArgsList[pid] = TimerArgsList[pid] or {}
        local datas = TimerArgsList[pid]
        datas[eid] = {args = table.pack(...), func = func}

        return eid
    end
end


function timerMgr.delTimer(player, eid)
    if type(eid) ~= "string" or not player or type(player) ~= "userdata"  then
        print("timerMgr.delTimer err", player, eid)
        return
    end

    local pid = player:getPid()
    local datas = TimerArgsList[pid]
    if not datas then
        print("timerMgr.delTimer no datas", pid)
        return
    end

    datas[eid] = nil

    gTimer:del(eid)

end

local function logout(player)
    local pid = player:getPid()
    local datas = TimerArgsList[pid] or {}
    for k, v in pairs(datas) do
        gTimer:del(k)
    end

    TimerArgsList[pid] = nil
end

serverEventMgr.reg(ServerEventDefine.logout, logout)
