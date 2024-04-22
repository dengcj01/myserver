

_G.globaModulelDataList = _G.globaModulelDataList or {}
_G.globaModulelDirtryList = _G.globaModulelDirtryList or {}

globalModuleDataMgr = {}



function gLoadGlobalModuleData(moduleId, data)
    local data = toolsMgr.decode(data)
    if data then
        globaModulelDataList[moduleId] = data
    else
        print("---------gLoadGlobalMuduleData err", moduleId)
    end
end

function gGetGlobalModuleData()
    local tab = {}

    for k, v in pairs(globaModulelDirtryList) do
        local data = globaModulelDataList[k] or {}
        
        if type(data) == "table" then
            if next(data) ~= nil then
                tab[k] = toolsMgr.encode(data)
            end
        else
            print("--------gGetGlobalModuleData err", k)
        end
    end

    return tab
end


function gTimerGetGlobalModuleData()
    return __TimerGetGlobalModuleData or {}
end


function globalModuleDataMgr.getGlobalData(moduleId)
    globaModulelDataList[moduleId] = globaModulelDataList[moduleId] or {} 
    return globaModulelDataList[moduleId]
end

function globalModuleDataMgr.saveGlobalData(moduleId)
    if globaModulelDirtryList[moduleId] == nil then
        globaModulelDirtryList[moduleId] = os.time() + math.random(120, 300)
    end
end

local function __timerSaveGlobalData(curTime)
    _G.__TimerGetGlobalModuleData = {}
    for k, v in pairs(globaModulelDirtryList) do
        if curTime >= v then
            local data = globaModulelDataList[k] or {}
            if type(data) == "table" then
                if next(data) ~= nil then
                    __TimerGetGlobalModuleData[k] = toolsMgr.encode(data)
                end
            else
                print("--------__timerSaveGlobalData err", k)
            end

            globaModulelDirtryList[k] = nil
        end
    end

    
    gMainThread:saveGlobalData(true)
    _G.__TimerGetGlobalModuleData = nil

end

serverEventMgr.reg(ServerEventDefine.serverMinute, __timerSaveGlobalData)