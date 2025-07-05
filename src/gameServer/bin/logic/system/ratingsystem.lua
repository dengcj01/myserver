
local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"

local ratingLevelConfig = require "logic.config.ratingLevel"
local ratingLevelUnlockConfig = require "logic.config.ratingLevelUnlock"
local dropsystem = require "logic.system.dropsystem"
local bagsystem = require "logic.system.bagsystem"
local playersystem = require "logic.system.playersystem"
local playermoduledata = require "common.playermoduledata"


local herosystem = require "logic.system.hero.herosystem"
local tasksystem = require "logic.system.tasksystem"

local adventuresystem = require "logic.system.adventuresystem"




local openConditionType = {
    none = 0, -- 无条件
    level = 1, -- 评价等级
    card = 2, -- 关卡
    task = 3 -- 任务
}

-- 解锁等级缓存
local ratingLevelUnlockCacheConfig = {}
for k, v in pairs(ratingLevelUnlockConfig) do
    local type = v.open_condition[1]
    ratingLevelUnlockCacheConfig[type] = ratingLevelUnlockCacheConfig[type] or {}
    local cfg = ratingLevelUnlockCacheConfig[type]
end

local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.rating)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.rating)
end

local function getUnLockData(player, id)
    id = tostring(id)
    local data = getData(player)
    if not data.unlock then
        data.unlock = {}
    end

    if not data.unlock[id] then
        data.unlock[id] = {}
    end

    return data.unlock[id]

end



-----------------------------------培养-----------------------------------
local function ReqAdviceLevelup(player, pid, proto)
    local id = define.currencyType.ratingExp
    local level = player:getLevel()
    local currExp = bagsystem.getCurrencyNumById(player, id)
    local config = ratingLevelConfig[level]
    if not config then
        print("ReqAdviceLevelup no config", pid, level)
        return
    end

    local nextLv = level + 1
    local nextConfig = ratingLevelConfig[nextLv]
    if not nextConfig then
        print("ReqAdviceLevelup no nextLv", pid, level)
        return
    end

    local awards = {}
    local val = config.exp
    if not val or val > currExp then
        print("ReqAdviceLevelup no enough exp", pid, level, val, currExp)
        return
    end

    local cost = {{id = id,type = define.itemType.currency, count = val}}

    bagsystem.costItems(player, cost)


    local rewards = {}
    if config.reward then
        local itemlist = dropsystem.getDropItemList(config.reward)
        for k, item in pairs(itemlist or {}) do
            table.insert(rewards, item)
        end
    end


    if #rewards then
        local notice = bagsystem.makeNotice(nextLv)
        bagsystem.addItems(player, rewards, define.rewardTypeDefine.playerUpLevel, notice)
    end
    
    


    _G.gluaFuncAddNewFunctionOpen(player, nextLv)
    player:setLevel(nextLv)
    net.sendMsg2Client(player, ProtoDef.ResAdviceLevelup.name, {level=nextLv})



    
    playersystem.updatePlayerBaseInfo(pid, {level = nextLv})

    _G.gluaFuncRatingUnlock(player, pid)

    tasksystem.updateProcess(player, pid, define.taskType.playerLv, {nextLv}, define.taskValType.cover)

end

local function notifySetSignature(player)
    local data = getData(player)
    local res = {}
    res.sign = data.sign or ""

    net.sendMsg2Client(player, ProtoDef.NotifySetSignature.name, res)
end

local function notifySetMyHeros(player)
    local data = getData(player)
    local res = {}
    res.ids = data.ids or {}

    net.sendMsg2Client(player, ProtoDef.NotifySetMyHeros.name, res)
end

local function ReqSetSignature(player, pid, proto)
    local sign = proto.sign

    local data = getData(player)
    data.sign = sign

    notifySetSignature(player)
end

local function ReqSetMyHeros(player, pid, proto)
    local ids = proto.ids

    if #ids > 0 then
        for k, v in pairs(ids) do
            if not herosystem.getHeroById(player, v) then
                print("ReqSetMyHeros not find heroid ", pid, v)
                return
            end
        end
    end

    local data = getData(player)
    data.ids = ids

    notifySetMyHeros(player)
end

local function writePackUnLock(player, id)
    local data = getUnLockData(player, id)

    local msc = {}
    msc.unLockData = {}
    for k, v in pairs(data) do
        table.insert(msc.unLockData, {
            id = id,
            value = (v or 0),
            param = tonumber(k)
        })
    end

    return msc
end
local function onUnLock(player, pid, proto, isAuto, level)
    local id,isGold = proto.id,proto.isGold
    local config = ratingLevelUnlockConfig[id]
    if not config then
        return
    end

    if isAuto and config.consume and  #config.consume > 0 then
        return
    end

    if #config.open_condition > 0 and #config.open_condition ~= #config.parameter then
        return
    end

    if config.open_condition and #config.open_condition > 0 then
        for k, v in ipairs(config.open_condition) do
            local key = (config.parameter[k] or 0)
            if v == openConditionType.level then
                if level < key then
                    return
                end
            elseif v == openConditionType.card and adventuresystem.getAdvThroughtCount(player, key) <= 0 then
                return
            elseif v == openConditionType.task and not tasksystem.taskIsCompleteByType(player, key, v) then
                return
            end
        end
    end

    local unlockType, unlockParam, unlockTarget = config.effect[1], config.effect[2], (config.effect[3] or 0)
    if #(config.effect or {}) <= 2 then
        unlockTarget = unlockParam
        unlockParam = 0
    end

    local data = getUnLockData(player, unlockType)
    local skey = tostring(unlockParam)
    local val = data[skey] or 0
    if val >= unlockTarget then
        return
    end

    local costs = {}
    for k, v in pairs(config.consume or {}) do
        if isGold and v[1] == define.currencyType.gold then
            table.insert(costs, {
                id = v[1],
                count = v[2],
                type = define.itemType.currency
            })
            break
        elseif v[1] == define.currencyType.jade then
            table.insert(costs, {
                id = v[1],
                count = v[2],
                type = define.itemType.currency
            })
            break 
        end
        
    end


    if #costs > 0 and not bagsystem.checkAndCostItem(player, costs) then
        return
    end

    data[skey] = unlockTarget

    saveData(player)

    local res = {}
    res.unLockData = {
        id = unlockType,
        value = unlockTarget,
        param = unlockParam
    }
    
    net.sendMsg2Client(player, ProtoDef.ResUnlock.name, res)

    if proto.flag then
        tasksystem.updateProcess(player, pid, define.taskType.lockWorkShopCnt, {1}, define.taskValType.add, {unlockParam})
    end
    

end

local function ReqUnlock(player, pid, proto)
    proto.flag = true
    local level = player:getLevel()
    onUnLock(player, pid, proto, nil, level)
end

local function ReqUnlockData(player, pid, proto)
    local data = getData(player)
    local res = {unlockListData = {}}

    for k, v in pairs(data.unlock or {}) do
        local temp = writePackUnLock(player, k)
        table.insert(res.unlockListData, temp)
    end
    
    net.sendMsg2Client(player, ProtoDef.ResUnlockData.name, res)
end

local function RatingUnlock(player, pid, level)
    level = level or player:getLevel()
    for i, v in ipairs(ratingLevelUnlockConfig) do
        local proto = {id = v.id,isGold = false}
        onUnLock(player, pid, proto, true, level)
    end

end

local function GetRatingUnlock(player, unlockType, param)
    local data = getUnLockData(player, unlockType)

    return data[tostring((param or 0))] or 0
end


local function login(player, pid, curTime, isfirst)
    notifySetSignature(player)
    notifySetMyHeros(player)
end


local function setPlayerLevel(player, pid, args)
    local lv = args[1]
    if not lv then
        return
    end
    
    local level = player:getLevel()
    if lv <= level then
        return
    end

    _G.gluaFuncAddNewFunctionOpen(player, lv)

    player:setLevel(lv)

    local res = {}
    res.level = lv

    net.sendMsg2Client(player, ProtoDef.ResAdviceLevelup.name, res)




    _G.gluaFuncRatingUnlock(player, pid)

    tasksystem.updateProcess(player, pid, define.taskType.playerLv, {lv}, define.taskValType.cover)
end

local function setplayerlevel(player, pid, args)
    --player = gPlayerMgr:getPlayerById(283204139194777)
    setPlayerLevel(player, pid, args)
end

local function setplayerlevel1(player, pid, args)
    player = gPlayerMgr:getPlayerById(3518438940388501242)
    --setPlayerLevel(player, 3518438940388501242, {99})
end

gm.reg("setplayerlevel", setplayerlevel)
gm.reg("setplayerlevel1", setplayerlevel1)

_G.gluaFuncRatingUnlock = RatingUnlock
_G.gluaFuncGetRatingUnlock = GetRatingUnlock

event.reg(event.eventType.login, login)

net.regMessage(ProtoDef.ReqAdviceLevelup.id, ReqAdviceLevelup, net.messType.gate)
net.regMessage(ProtoDef.ReqSetSignature.id, ReqSetSignature, net.messType.gate)
net.regMessage(ProtoDef.ReqSetMyHeros.id, ReqSetMyHeros, net.messType.gate)
net.regMessage(ProtoDef.ReqUnlockData.id, ReqUnlockData, net.messType.gate)
net.regMessage(ProtoDef.ReqUnlock.id, ReqUnlock, net.messType.gate)
