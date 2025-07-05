
local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"
local util = require "common.util"
local playermoduledata = require "common.playermoduledata"

local functionOpenConfig = require "logic.config.functionOpen"



local tasksystem = require "logic.system.tasksystem"

-- 功能开启条件
local functionOpenType =
{
    defalut = 0, -- 默认无条件解锁
    level = 1, -- 玩家等级
    checkpoint = 2, -- 主线关卡
    newPersonTask = 3, -- 新手任务
}    



local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.functionopen)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.functionopen)
end



local function ReqFunctionOpenInfo(player, pid, proto)
    local datas = getData(player)

    if not datas then
        return
    end

    local msgs = {list = {}}
    local list = msgs.list
    for k, v in pairs(datas.list or {}) do
        table.insert(list, v)
    end

    net.sendMsg2Client(player, ProtoDef.ResFunctionOpenInfo.name, msgs)
end


local function AddNewFunctionOpen(player, level, notice)
    local datas = getData(player)
    if not datas then
        return
    end

    datas.list = datas.list or {}
    local list = datas.list


    if notice == nil then
        notice = true
    end

    local level = level or player:getLevel()
    local id = _G.gluaFuncGetCheckpointId(player)
    local newList = {}
    local msgs = {}
    local ret = {}

    for _, functionId in pairs(define.functionOpen) do
        repeat
            local cfg = functionOpenConfig[functionId]
            if not cfg then
                break
            end

            if tools.isInArr(list, functionId) then
                break     
             end

             local ok = true
             for k, v in ipairs(cfg.open_condition) do
                local val = cfg.parameter[k] or 0
        
                if v == functionOpenType.defalut then
                    ok = true
                elseif v == functionOpenType.level then
                    if level < val then
                        ok = false
                        break
                    end
                elseif v == functionOpenType.checkpoint then
                    if id < val then
                        ok = false
                        break
                    end
                elseif v == functionOpenType.newPersonTask then
                    if not tasksystem.taskIsCompleteByType(player, val, define.taskTypeDef.newPerson) then
                        ok = false
                        break
                    end
                end
            end

            if ok then
                table.insert(list, functionId)
                table.insert(newList, functionId)
                ret[functionId] = 1
            end
        until true
    end


    if next(newList) then
        saveData(player)

        if notice then
            -- print("sssssssssssssssssssssss")
            -- tools.ss(msgs)
            msgs.list = newList
            net.sendMsg2Client(player, ProtoDef.NotifyFunctionOpenUpdate.name, msgs)
        end
    end

    if ret[define.functionOpen.bank] then
        _G.gluaFuncAddNewCarrige(player, {isFuncopen=1,idx=1})
    end
    if ret[define.functionOpen.tower] then
        _G.gLuaFuncInitTowerData(player)
    end
    if ret[define.functionOpen.boss] then
        _G.gLuaFuncInitBossData(player)
    end

    return ret
end

local function FuntionIsOpen(player, functionId)
    local datas = getData(player)

    if not datas then
        return
    end

    local list = datas.list or {}

    local ret = tools.isInArr(list, functionId)

    return ret
end

local function login(player, pid, curTime, isfirst)
    AddNewFunctionOpen(player, nil, false)
end


local function testfuncopendata(player, pid, args)
    login(player, pid)

    tools.ss(getData(player))
end

local function showfuncopendata(player, pid, args)
    player = gPlayerMgr:getPlayerById(3518438939847019155)
    tools.ss(getData(player))
end

local function cleanuncopendata(player, pid, args)
    local datas = getData(player)
    tools.cleanTableData(datas)
    saveData(player)
    tools.ss(datas)
end

local function cleanandsetuncopendata(player, pid, args)
    cleanuncopendata(player, pid, args)
    testfuncopendata(player, pid, args)
end

gm.reg("testfuncopendata", testfuncopendata)
gm.reg("showfuncopendata", showfuncopendata)
gm.reg("cleanuncopendata", cleanuncopendata)
gm.reg("cleanandsetuncopendata", cleanandsetuncopendata)


_G.gluaFuncAddNewFunctionOpen = AddNewFunctionOpen
_G.gluaFuncFuntionIsOpen = FuntionIsOpen

event.reg(event.eventType.login, login)

net.regMessage(ProtoDef.ReqFunctionOpenInfo.id, ReqFunctionOpenInfo, net.messType.gate)



