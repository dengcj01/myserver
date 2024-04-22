
_G.playerModeleDataList = _G.playerModeleDataList or {}
_G.playerModeleDataDirtyList = _G.playerModeleDataDirtyList or {}

playerModuleDataMgr = {}



function gLoadPlayerModuleData(pid, moduleId, sdata)
    playerModeleDataList[pid] = playerModeleDataList[pid] or {}
    playerModeleDataDirtyList[pid] = nil
    
    local datas = playerModeleDataList[pid]
    local data = toolsMgr.decode(sdata)
    if data then
        datas[moduleId] = data
    else
        print("---------gLoadPlayerModuleData err", pid, moduleId)
    end
end

function gRemoveAllModuleData(pid)
    playerModeleDataList[pid] = nil
    playerModeleDataDirtyList[pid] = nil
end


function gGetPlayerModuleData(pid, mod)
    -- if mod == 3 then -- 伪登录强制保存数据
    --     local datas = playerModeleDataList[pid] or {}
    --     local tab = {}

    --     if type(datas) == "table" then
    --         for k, v in pairs(datas) do
    --             if type(v) == "table" then
    --                 if next(v) ~= nil then
    --                     tab[k] = toolsMgr.encode(v)
    --                 end
    --             else 
    --                 print("gGetPlayerModuleData err1", pid, mod)
    --             end
    --         end
    --     else
    --         print("gGetPlayerModuleData err2", pid)
    --     end

    --     playerModeleDataList[pid] = nil
    --     playerModeleDataDirtyList[pid] = nil
    --     return tab
    -- end
    

    local dirtyData = playerModeleDataDirtyList[pid]
    if not dirtyData then
        return {}
    end

    local tab = {}


    local datas = playerModeleDataList[pid] or {}
    for k, v in pairs(dirtyData) do
        local data = datas[k] or {}
        if type(data) == "table" then
            if next(data) ~= nil then
                tab[k] = toolsMgr.encode(data)
            end
        else
            print("gGetPlayerModuleData err2", pid, mod)
        end
    end
    
    playerModeleDataDirtyList[pid] = nil
    playerModeleDataList[pid] = nil


    return tab
end

function gTimerGetPlayerModuleData(pid, mod)
    return __TimerGetPlayerModuleData[pid] or {}
end




local function getPlayerModuleDataByPid(pid, moduleId)
    if pid == nil or type(pid) ~= "number" then
        print("getPlayerModuleDataByPid", pid, moduleId)
        return
    end

    playerModeleDataList[pid] = playerModeleDataList[pid] or {}
    local data = playerModeleDataList[pid]
    local myData = data[moduleId]
    if myData then
       return myData 
    end

    
    local fakePlayer = gPlayerMgr:getFakePlayer(pid)
    if fakePlayer then
        local vec = gPlayerMgr:loadFakePlayerData(pid, moduleId)
        if #vec > 0 then
            data[moduleId] = toolsMgr.decode(vec[1])
        else
            data[moduleId] = data[moduleId] or {}
        end
    else
        data[moduleId] = data[moduleId] or {}
    end

    return data[moduleId]
end



function playerModuleDataMgr.getData(player, moduleId)
    if player == nil or type(player) ~= "userdata" then
        print("playerModuleDataMgr.getData err", player, moduleId)
        return
    end

    return getPlayerModuleDataByPid(player:getPid(), moduleId)
end

function playerModuleDataMgr.saveData(player, moduleId)
    if player == nil or type(player) ~= "userdata" then
        print("playerModuleDataMgr.save err", player, moduleId)
        return
    end

    local pid = player:getPid()
    playerModeleDataDirtyList[pid] = playerModeleDataDirtyList[pid] or {}

    local data = playerModeleDataDirtyList[pid]
    if data[moduleId] == nil then
        data[moduleId] = os.time() + math.random(120, 300)
    end
    
end

local function __timerSavePlayerData(curTime)
    _G.__TimerGetPlayerModuleData = {}
    for pid, v in pairs(playerModeleDataDirtyList) do
        for moduleId, time in pairs(v) do
            if curTime >= time then
                local pdata = playerModeleDataList[pid]
                if pdata then
                    local mdata = pdata[moduleId] or {}
                    if type(mdata) == "table" then
                        if next(mdata) ~= nil then
                            __TimerGetPlayerModuleData[pid] = __TimerGetPlayerModuleData[pid] or {}
                            local data = __TimerGetPlayerModuleData[pid] 
                            data[moduleId] = toolsMgr.encode(mdata)   
                        end
                    else
                        print("--------__timerSavePlayerData err", pid, moduleId)
                    end
                end
                v[moduleId] = nil
            end
        end
    end


    for k, v in pairs(__TimerGetPlayerModuleData) do
        gPlayerMgr:savePlayerModuleData(k)
    end
    _G.__TimerGetPlayerModuleData = nil


end

serverEventMgr.reg(ServerEventDefine.serverMinute, __timerSavePlayerData)