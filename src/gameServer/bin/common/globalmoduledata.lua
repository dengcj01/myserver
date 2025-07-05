
local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"

local globaModulelTmpData = _G.globaModulelTmpData
local globaModulelDataList = _G.globaModulelDataList
local globaModulelDirtryList = _G.globaModulelDirtryList

local globalmoduledata = {}


function getGlobalModuleTmpData(moduleId)
    globaModulelTmpData[moduleId] = globaModulelTmpData[moduleId] or {}

    return globaModulelTmpData[moduleId]
end


function gLoadGlobalModuleData(moduleId, data)
    local data = tools.decode(data)
    if data then
        globaModulelDataList[moduleId] = data
    else
        print("---------gLoadGlobalMuduleData err", moduleId)
    end
end

local function getData(isTimer, curTime)
    local tab = {}

    for k, v in pairs(globaModulelDirtryList) do
        local data = globaModulelDataList[k] or {}
        
        if type(data) == "table" then
            local ok = true
            
            if isTimer then
                if curTime < v then
                    ok = false
                else
                    globaModulelDirtryList[k] = nil
                end
            end

            if ok then
                tab[k] = tools.encode(data)
            end
            
        else
            print("--------globalmoduledatagetData err", k)
        end
    end

    return tab
end

function gGetGlobalModuleData()
    local ret = getData()
    return ret
end


function globalmoduledata.getGlobalData(moduleId)
    globaModulelDataList[moduleId] = globaModulelDataList[moduleId] or {} 
    return globaModulelDataList[moduleId]
end

function globalmoduledata.saveGlobalData(moduleId)
    if globaModulelDirtryList[moduleId] == nil then
        globaModulelDirtryList[moduleId] = gTools:getNowTime() + math.random(120, 300)
    end
end


local function timerSaveGlobalData(curTime)
    local ret = getData(true, curTime)
    if next(ret) then
        gMainThread:saveGlobalData(ret, 0)
    end
end

local function testaddglobaldata(player, pid, args)
    local data = globalmoduledata.getGlobalData(5)
    data.aa = 1
    data.show = {a=1,b=2}
    globalmoduledata.saveGlobalData(5)
end

local function testsaveglobaldata(player, pid, args)
    local ret = gGetGlobalModuleData()
    gMainThread:saveGlobalData(ret, 0)
end

local function showdirtyglobaldata(player, pid, args)
    tools.ss(globaModulelDirtryList)
end

local function showglobaldata(player, pid, args)
    tools.ss(globaModulelDataList)
end

event.reg(event.eventType.serverMinute, timerSaveGlobalData)


gm.reg("testsaveglobaldata", testsaveglobaldata)
gm.reg("testaddglobaldata", testaddglobaldata)
gm.reg("showdirtyglobaldata", showdirtyglobaldata)
gm.reg("showglobaldata", showglobaldata)








return globalmoduledata