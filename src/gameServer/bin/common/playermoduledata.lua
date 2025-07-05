

local tools = require "common.tools"
local event = require "common.event"
local define = require "common.define"
local gm = require "common.gm"


local playermoduledata = {}
local playerTmpData = _G.playerTmpData
local playerModeleDataList = _G.playerModeleDataList
local playerModeleDataDirtyList = _G.playerModeleDataDirtyList


function playermoduledata.getPlayerTmpData(pid, moduleId)
    playerTmpData[pid] = playerTmpData[pid] or {}
    local tmpData = playerTmpData[pid]

    tmpData[moduleId] = tmpData[moduleId] or {}

    return tmpData[moduleId]
end

function gLoadPlayerModuleData(pid, moduleId, sdata)
    playerModeleDataList[pid] = playerModeleDataList[pid] or {}
    playerModeleDataDirtyList[pid] = nil
    
    local datas = playerModeleDataList[pid]
    local data = tools.decode(sdata)
    if data then
        datas[moduleId] = data

        if moduleId == define.playerModuleDefine.bag then
            _G.gluaFuncInitItemIndex(pid, data)
        end
    else
        print("---------gLoadPlayerModuleData err", pid, moduleId)
    end
end

function gRemoveAllModuleData(pid)
    playerModeleDataList[pid] = nil
    playerModeleDataDirtyList[pid] = nil
end

local function getOnePlayerData(pid, data, isTimer, curTime)
    local pdata = playerModeleDataList[pid] or {}
    local list = {}
    if type(pdata) == "table" then
        local ret = {}
        for moduleId, time in pairs(data) do
            local ok = true
            if isTimer then
                if curTime < time then
                    ok = false
                else
                    data[moduleId] = nil
                end
            end

            if ok then
                local mdata = pdata[moduleId]
                if type(mdata) == "table" then
                    ret[moduleId] = tools.encode(mdata)  
                else
                    print("--------playermoduledatagetData err1", pid, moduleId)
                end
            end
        end
        return ret
    else
        print("--------playermoduledatagetData err2", pid)
    end
end



function gGetPlayerModuleData(pid)
    local data = playerModeleDataDirtyList[pid]
    local ret = {}
    if data then
        ret = getOnePlayerData(pid, data) or {}
    end

    return ret
end


function playermoduledata.getPlayerModuleDataByPid(pid, moduleId)
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

    data[moduleId] = data[moduleId] or {}

    return data[moduleId]
end



function playermoduledata.getData(player, moduleId)
    if player == nil or type(player) ~= "userdata" then
        printTrace("playermoduledata.getData err", player, moduleId)
        return
    end

    return playermoduledata.getPlayerModuleDataByPid(player:getPid(), moduleId)
end

function playermoduledata.saveData(player, moduleId)
    if player == nil or type(player) ~= "userdata" then
        printTrace("playermoduledata.save err", player, moduleId)
        return
    end

    local pid = player:getPid()
    playermoduledata.saveDataByPid(pid, moduleId)
    
end

function playermoduledata.saveDataByPid(pid, moduleId)
    playerModeleDataDirtyList[pid] = playerModeleDataDirtyList[pid] or {}

    local data = playerModeleDataDirtyList[pid]
    if data[moduleId] == nil then
        data[moduleId] = gTools:getNowTime() + math.random(120, 300)
        --data[moduleId] = gTools:getNowTime() + math.random(10, 10)
    end
end


local function timerSavePlayerData(curTime, playerList)
    local fakeList = gPlayerMgr:getFakeList()
    for pid, v in pairs(playerModeleDataDirtyList) do
        local ret = getOnePlayerData(pid, v, true, curTime) or {}
        local player = playerList[pid]
        if not player then
            player = fakeList[pid]
        end

        if player and next(ret) then
            player:saveModuleData(pid, ret, 0);
        end
    end
end

local function logout(player, pid, curTime)
    playerTmpData[pid] = nil
end


local function showplayrmoduledird(player, pid, args)
   tools.sss(playerModeleDataDirtyList)
   print("xxx")
end

local function gmfakelogin(player, pid, args)
    pid = 141735396401728

    player = gPlayerMgr:fakeLoad(pid, 8)
    local data = playermoduledata.getData(player, 8)
    data.test = 1111
    playermoduledata.saveData(player, 8)
    print("xxx")
end

local function gmtest1(player, pid, args)
    pid = 141735396401728
    player = gPlayerMgr:getPlayerById(pid)

    local data = playermoduledata.getData(player, 8)
    data.test = 100
    playermoduledata.saveData(player, 8)
    print("xxx")
end

local function gmshowplayerdata(player, pid, args)
    pid = 141735396401728
    tools.sss(playerModeleDataList)
end

gm.reg("showplayrmoduledird", showplayrmoduledird)
gm.reg("gmshowplayerdata", gmshowplayerdata)
gm.reg("gmfakelogin", gmfakelogin)
gm.reg("gmtest1", gmtest1)

event.reg(event.eventType.logout, logout)
event.reg(event.eventType.serverMinute, timerSavePlayerData)

return playermoduledata