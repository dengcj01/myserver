local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"
local msgCode = require "common.model.msgerrorcode"
local util = require "common.util"
local furnitureConfig = require "logic.config.furniture"
local orderCustomerEquipConfig = require "logic.config.order_CustomerEquip"
local orderHeroEquipConfig = require "logic.config.order_HeroEquip"
local orderPrincessConfig = require "logic.config.order_Princess"
local orderPeopleConfig = require "logic.config.order_people"
local orderWorkerEquipConfig = require "logic.config.order_WorkerEquip"
local orderWorkerMaterialConfig = require "logic.config.order_WorkerMaterial"
local orderWorkerSpecialConfig = require "logic.config.order_WorkerSpecialConfig"
local ratingLevelUnlockConfig = require "logic.config.ratingLevelUnlock"
local constConfig = require "logic.config.constConfig"
local shopConfig = require "logic.config.shopConfig"
local equipConfig = require "logic.config.equip"
local formulaConfig = require "logic.config.equipFormula"
local furnitureLevelupConfg = require "logic.config.furnitureLevelup"
local playermoduledata = require "common.playermoduledata"
local bagsystem = require "logic.system.bagsystem"
local tasksystem = require "logic.system.tasksystem"
local itemConfig = require "logic.config.itemConfig"
local systemConfig = require "logic.config.system"
local timerMgr = require "common.timer"
local furnituresystem = {}

local cachefurnitureLevelupConf = {}
for k, v in pairs(furnitureLevelupConfg) do
    local id = v.furnitureId
    cachefurnitureLevelupConf[id] = cachefurnitureLevelupConf[id] or {}
    local data = cachefurnitureLevelupConf[id]
    local lv = v.level
    data[lv] = v
end

-- 柜台id
local guitaiIdDef = 100001
local chuwuxiangIdDef = 110001


-- 家具类型定义
local furnituresTypeDef = {
    furnitures = 1, -- 家具类   可以重复获得
    baijian = 2 -- 摆件类型    重复获得转为材料
}

-- 家具类型定义
local furnituresSubTypeDef = {
    equiprEveal = 1, -- 装备展示
    materialStorage = 2, -- 材料存储
    floor = 6 -- 地板
}

local upLevelCostType = {
    goldType = 1, -- 通币类型
    jadeType = 2, -- 仙玉类型
    fragmentType = 3 -- 碎片类型
}

local furnitureKind = {
    item = 1, -- 1.道具
    equip = 2, -- 2.装备
    currency = 3, -- 3.货币
    furniture = 4, -- 4.家具
    doorman = 5 -- 5.门客
}

-- 房间解锁顺序,默认2号位置解锁
local roomUnlockOrder = {2, 3, 1, 6, 5, 4, 9, 8, 7}

local G_EnumDefine = {
    TALK_TYPE = {
        NO = 1,
        SUCCESS = 2,
        FAIL = 3
    },
    PRICE_TYPE = {
        NO = 1,
        RISE = 2, ---- 涨价 /多付
        DISCOUNT = 3 -- 折扣 /少付
    }

}

local __EnumDefine = {}
__EnumDefine.TALK_TYPE = {
    NO = 1,
    SUCCESS = 2,
    FAIL = 3
}

__EnumDefine.PRICE_TYPE = {
    NO = 1,
    RISE = 2, ---- 涨价 /
    discount = 3, -- 折扣 
    more = 4, -- 多付
    less = 5 -- 少付
}



-- 家具控制装备格子上限的id列表
local equipFurnitureList = {110001, 110002, 110003, 110004, 110005}

-- 家具控制普通材料堆叠限的id列表
local itemFurnitureList = {120001, 120002, 120003, 120004, 120005, 120006, 120007, 120008, 120009, 120010, 120011,120012}

local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.furniture)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.furniture)
end

local function getCacheSpaceData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.cacheSpace)
end

local function saveCacheSpaceData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.cacheSpace)
end

local function getNpcData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.npc)
end

local function saveNpcData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.npc)
end

local function getTmpData(pid)
    return playermoduledata.getPlayerTmpData(pid, define.playerTmpDataIdDefine.npc)
end

-- 特殊npc类型定义
local specialNpcType = {
    formula = 1, -- 图纸npc
    trade = 2 -- 交易npc
}


local function getNextTimeIdxAndTime(conf, timeIdx)
    local timeIdx = timeIdx + 1
    local sellTime = conf.sellTime
    local maxCnt = #sellTime
    if timeIdx > maxCnt then
        timeIdx = 1
    end

    sellTime = sellTime[timeIdx]
    local randTime = math.random(sellTime[1], sellTime[2])
    --randTime = 10

    return timeIdx, randTime
end

local function getItemEquipNextTimeIdxAdnTime(conf, timeIdx)
    local sellTime = conf.sellTime
    local maxIdx = #sellTime
    timeIdx = timeIdx + 1
    if timeIdx > maxIdx then
        timeIdx = 1
    end

    sellTime = sellTime[timeIdx]
    local randTime = math.random(sellTime[1], sellTime[2])
    --randTime = 5

    return timeIdx, randTime

end

local function packRoom(id, data)
    local msg = {}
    msg.id = tonumber(id)
    msg.extendStartTime = data.extendStartTime or 0
    msg.extendCompleteTime = data.extendCompleteTime or 0
    msg.wallDatas = data.wallDatas or {}
    msg.helpPlayerList = data.helpPlayerList or {}

    return msg
end

local function packRoomInfo(room, msgs)
    for k, v in pairs(room or {}) do
        local msg = packRoom(k, v)
        table.insert(msgs, msg)
    end
end

local function packFurniture(guid, id, data)
    local msg = {}
    msg.guid = guid
    msg.id = id
    msg.minPos = data.minPos or {}
    msg.maxPos = data.maxPos or {}
    msg.level = data.level or 1
    msg.isFlip = data.isFlip or false
    msg.isStore = data.isStore or false
    msg.skinId = data.skinId or 0
    msg.upgradeStartTime = data.upgradeStartTime or 0
    msg.upgradeCompleteTime = data.upgradeCompleteTime or 0



    msg.helpPlayerList = data.helpPlayerList or {}
    return msg
end

local function packFurnitureInfo(furnitureList, msgs)
    for k, v in pairs(furnitureList or {}) do
        local msg = packFurniture(k, v.id, v)
        table.insert(msgs, msg)
    end
end



local function getFurnitureLevelup(id, level, useFirst)
    local cfg = cachefurnitureLevelupConf[id]
    if not cfg then
        if useFirst == true then
            return furnitureLevelupConfg[1]
        end
        return
    end

    local conf = cfg[level]
    if not conf then
        if useFirst == true then
            return furnitureLevelupConfg[1]
        end
        return
    end

    return conf
end

local function getGuitaiAddVal(datas)
    local furnitureList = datas.furnitureList or {}
    local data = furnitureList[datas.guitaiId]
    if not data then
        return 0
    end

    local cfg = getFurnitureLevelup(data.id, data.level)
    if not cfg then
        return 0
    end

    return cfg.param / 10000
end

local function updateCacheSpaceData(player, pid, id, fconf, cacheSpaceData, oldCfg, newCfg)
    local cacheSpaceData = cacheSpaceData or getCacheSpaceData(player)
    if cacheSpaceData and oldCfg then
        local itemCache = cacheSpaceData.itemCache
        local goodWillId = tostring(define.currencyType.goodWill)
        if tools.isInArr(equipFurnitureList, id) then
            if newCfg then
                cacheSpaceData.equipSpace = cacheSpaceData.equipSpace + (newCfg.capacity - oldCfg.capacity)

                if id == chuwuxiangIdDef then
                    cacheSpaceData.rareLeftSpace = cacheSpaceData.rareLeftSpace + (newCfg.param - oldCfg.param)
                else
                    itemCache[goodWillId] = itemCache[goodWillId] + (newCfg.param - oldCfg.param)
                end
            else
                cacheSpaceData.equipSpace = (cacheSpaceData.equipSpace or 0) + oldCfg.capacity

                local param = oldCfg.param
                if id == chuwuxiangIdDef then
                    cacheSpaceData.rareLeftSpace = (cacheSpaceData.rareLeftSpace or 0) + param
                else
                    itemCache[goodWillId] = itemCache[goodWillId] + param
                end
            end

        end

        if tools.isInArr(itemFurnitureList, id) then
            local itemId = tostring(fconf.params[1][1])
            local itemCache = cacheSpaceData.itemCache

            if newCfg then
                local addVal = newCfg.capacity - oldCfg.capacity
                itemCache[itemId] = itemCache[itemId] + addVal
            else
                itemCache[itemId] = (itemCache[itemId] or 0) + oldCfg.capacity
            end
        end

    end
end

local function initFurnitureData(player, pid, id, furnitureList, newList, extra)
    local cfg = furnitureConfig[id]
    if not cfg then
        print("initFurnitureData err", pid, id)
        return
    end

    local uid = gTools:createUniqueId()
    local sid = tostring(uid)

    furnitureList[sid] = {
        id = id,
        isStore = true,
        level = 1,
    }

    local data = furnitureList[sid]
    if extra.furnitrurePos then
        local furnitrurePos = extra.furnitrurePos
        local posData = furnitrurePos[id] or {}

        if extra.initFurnitrure then
            data.minPos = {x=posData[1],y=posData[2]}
            data.maxPos = {x=posData[3],y=posData[4]}
        else
            data.minPos = posData.minPos
            data.maxPos = posData.maxPos
        end

        data.isStore = false
    end

    if extra.isFlip then
        data.isFlip = extra.isFlip
    end

    local goodsShelfData = cfg.goodsShelfData or {}

    data.useList = {}
    data.showData = {}

    if next(goodsShelfData) then
        data.nowIdx = 1
        local idxCfg = goodsShelfData[1]
        for k, v in pairs(idxCfg) do
            table.insert(data.useList, k)
        end

        data.nextId = #idxCfg
    end

    newList[uid] = furnitureList[sid]

    return sid
end

function furnituresystem.haveThistFurniture(player, id)
    local data = getData(player, id)

    local haveList = data.haveList or {}
    return haveList[tostring(id)]

end

function furnituresystem.checkIsRepeatableHas(player, id)
    local data = furnituresystem.haveThistFurniture(player, id)
    if not data then
        return true
    end

    local config = furnitureConfig[id]
    if not config then
        return false
    end

    return next(config.numb) == nil
    --return config.kind == furnituresTypeDef.furnitures
end

function furnituresystem.isRepeatableHas(id)
    local config = furnitureConfig[id]
    if not config then
        return false
    end

    return next(config.numb) == nil
    --return config.kind == furnituresTypeDef.furnitures
end

function furnituresystem.getFurnitureDataByUid(player, uid)
    local data = getData(player)
    if not data then
        return
    end

    local furnitureList = data.furnitureList or {}

    return furnitureList[tostring(uid)]

end

local function AddFurnitures(player, pid, itemList, cacheSpaceData, furnRd, extra)
    local datas = getData(player)
    if not datas then
        return
    end

    if next(itemList) == nil then
        return
    end

    datas.furnitureList = datas.furnitureList or {}
    local furnitureList = datas.furnitureList

    datas.haveList = datas.haveList or {}
    local haveList = datas.haveList

    datas.baijianList = datas.baijianList or {} -- 摆件类型id
    local baijianList = datas.baijianList
    local logs = {}
    local newList = {}

    for id, cnt in pairs(itemList) do
        local sid = tostring(id)
        local cfg = furnitureConfig[id]

        tasksystem.updateProcess(player, pid, define.taskType.furnitureLevelType, {cnt}, define.taskValType.add,
            {1, cfg.type})
        if cfg.kind == furnituresTypeDef.furnitures then
            for i = 1, cnt do

                local sid = initFurnitureData(player, pid, id, furnitureList, newList, extra)
                if sid and id == guitaiIdDef and datas.guitaiId == nil then
                    datas.guitaiId = sid
                end


                local lvCfg = getFurnitureLevelup(id, 1)
                updateCacheSpaceData(player, pid, id, cfg, cacheSpaceData, lvCfg)
            end

            tasksystem.updateProcess(player, pid, define.taskType.furnitureCnt, {cnt}, define.taskValType.add, {id})
            tools.accRdCount(furnRd, id, cnt)
        else
            if baijianList[sid] == nil then
                baijianList[sid] = 1
                initFurnitureData(player, pid, id, furnitureList, newList, extra)

                tasksystem.updateProcess(player, pid, define.taskType.furnitureCnt, {1}, define.taskValType.add, {id})
                tools.accRdCount(furnRd, id, 1)
            end
        end

        if (datas.floorId or 0) <= 0 and cfg.type == furnituresSubTypeDef.floor then
            datas.floorId = id
        end

        haveList[sid] = 1
    end

    saveData(player)

    if next(newList) then
        local msgs = {
            furnitureDatas = {}
        }
        packFurnitureInfo(newList, msgs.furnitureDatas)

        net.sendMsg2Client(player, ProtoDef.NotifyAddNewFurnitrue.name, msgs)
    end

end

local function packSellInfo(id, data)
    local msg = {}
    msg.id = id
    msg.type = data.type or 0
    msg.characterId = data.characterId or 0
    msg.characterLv = data.characterLv or 0
    msg.pos = data.pos or {}
    msg.price = data.price or 0
    msg.itemInfo = data.itemInfo or {}
    msg.talkType = data.talkType or 0
    msg.priceType = data.priceType or 0
    msg.showData = data.showData or {}
    msg.fuid = data.fuid or ""
    msg.equipIds = data.equipIds or {}
    msg.npcType = data.npcType or 0
    msg.makeEndTime = data.makeEndTime or 0
    msg.makeCnt = data.makeCnt or 0
    msg.maxCnt = data.maxCnt or 0
    msg.idx = data.idx or 0
    msg.addEnergy = data.addEnergy or 0
    msg.energy = data.goodWill or 0
    return msg
end

local function packSellTypeInfo(type, data)
    local msg = {}
    msg.type = tonumber(type or 0)
    msg.finishTime = (data and data.finishTime) or 0
    msg.finishCount = (data and data.finishCount) or 0
    msg.createTime = (data and data.createTime) or 0
    msg.createCount = (data and data.createCount) or 0

    return msg
end

local function getAddition(player, equipId, addType)
    local config = equipConfig[equipId]
    if not config then
        return 0
    end

    local rdT = _G.gluaFuncGetWorkShopEffect(player, define.MAP_TYPE.SMILING) or 0
    if type(rdT) ~= "table" then
        return 0
    end

    if addType == define.__ADDITION_TYPE.RISE_ENERGY_DECR then
        return (rdT[1] or 0)
    elseif addType == define.__ADDITION_TYPE.DISCOUNT_ENERGY_INCR then
        return (rdT[2] or 0)
    end

    return 0
end

local function getShopConsumeEnergyReduce(player, baseValue, equipId)
    local value = getAddition(player, equipId, define.__ADDITION_TYPE.RISE_ENERGY_DECR)
    value = value / 10000
    local finalVal = baseValue - math.ceil(baseValue * value)
    finalVal = finalVal < 1 and 1 or finalVal

    return finalVal
end

-- 降价获得善意增加
local function getShopAddEnergyAdd(player, baseValue, equipId)
    local value = getAddition(player, equipId, define.__ADDITION_TYPE.DISCOUNT_ENERGY_INCR)
    value = value / 10000
    local finalVal = baseValue + math.ceil(baseValue * value)
    return finalVal
end

-- 加速消耗的善意减少比例
local function getManufactureSPReduceEnergy(player, baseValue, equipId)
    local value = getAddition(equipId, define.__ADDITION_TYPE.SPEED_UP_ENERGY_DECR)
    local finalVal = baseValue - math.ceil(baseValue * value)
    if finalVal <= 1 then
        finalVal = 1
    end
    return finalVal
end

local function ReqNpcInfo(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqNpcInfo no datas", pid)
        return
    end

    local msgs = {
        sellData = {},
        sellTypeData = {}
    }

    for k, v in pairs(datas.sellData or {}) do
        local msg = packSellInfo(k, v)
        table.insert(msgs.sellData, msg)
    end

    for k, v in pairs(datas.sellTypeData or {}) do
        local msg = packSellTypeInfo(k, v)
        table.insert(msgs.sellTypeData, msg)
    end

    net.sendMsg2Client(player, ProtoDef.ResNpcInfo.name, msgs)
end

local function ReqNpcData(player, pid, proto)
    local npcData = getTmpData(pid)
    if not npcData then
        return
    end

    local msgs = {}
    local comNpc = tools.clone(npcData.comNpc or {})
    npcData.comNpc = nil

    msgs.data = comNpc
    net.sendMsg2Client(player, ProtoDef.ResNpcData.name, msgs)

end

local function initFloorId(player)
    local datas = getData(player)
    if (datas.floorId or 0) > 0 then
        return
    end

    for k, v in pairs(datas.furnitureList or {}) do
        local cfg = furnitureConfig[v.id]
        if cfg and cfg.type == furnituresSubTypeDef.floor then
            datas.floorId = v.id
            saveData(player)
            break
        end
    end

end

local function ReqFurnitureInfo(player, pid, proto)
    initFloorId(player)
    local datas = getData(player)
    if not datas then
        print("ReqFurnitureInfo no datas", pid)
        return
    end

    datas.room = datas.room or {}
    local room = datas.room
    local ok = false

    local defaultIdx = tostring(roomUnlockOrder[1])
    if not room[defaultIdx] then
        room[defaultIdx] = {}
        ok = true
    end

    if ok then
        saveData(player)
    end

    local msgs = {
        roomDatas = {},
        furnitureDatas = {}
    }

    msgs.floorId = datas.floorId or 0

    packRoomInfo(room, msgs.roomDatas)
    packFurnitureInfo(datas.furnitureList, msgs.furnitureDatas)

    net.sendMsg2Client(player, ProtoDef.ResFurnitureInfo.name, msgs)
end

local function updateTypeData(sellType, stype, sellTypeData, findData, reason)
    if findData then
        findData.finishCount = findData.finishCount and findData.finishCount or 0
        findData.createCount = findData.createCount and findData.createCount or 0
    else
        sellTypeData[stype] = {
            finishCount = 0,
            finishTime = 0,
            createCount = 0,
            createTime = 0
        }
    end

    if reason == "create" then
        findData.createCount = findData.createCount + 1
        findData.createTime = gTools:getNowTime()
    elseif reason == "finish" then
        findData.finishCount = findData.finishCount + 1
        findData.finishTime = gTools:getNowTime()
    end

end

local function ReqSetSellOrder(player, pid, proto)
    local uid, type, pos, charId, charLv, itemInfo, fuid, idx, npcType = proto.uid, proto.type, proto.pos, proto.charId,
        proto.charLv, proto.itemInfo, proto.fuid, proto.idx, proto.npcType

    local datas = getData(player)
    if not datas then
        print("ReqSetSellOrder no datas", pid)
        return
    end

    local npcData = getNpcData(player)
    if not npcData then
        print("ReqSetSellOrder no npcData", pid)
        return
    end

    local id = gTools:createUniqueId()
    local sid = tostring(id)

    local nowTime = gTools:getNowTime()
    local spNpcData = {}
    local makeEndTime = nil

    if npcType == specialNpcType.formula then
        spNpcData = npcData.formulaNpc[idx]
        local itemId = spNpcData.itemId or 0

        local conf = formulaConfig[itemId]
        if not conf then
            print("ReqSetSellOrder no cfg", pid, itemId)
            return
        end

        local itemCfg = itemConfig[itemId]
        if not itemCfg then
            print("ReqSetSellOrder no itemCfg", pid, itemId)
            return
        end

        if itemCfg.type ~= define.itemSubType.normalFormula then
            print("ReqSetSellOrder no normal formula", pid, itemId)
            return
        end

        makeEndTime = nowTime + conf.outputTime * spNpcData.maxCnt
        -- makeEndTime = nowTime + 20 * spNpcData.maxCnt
        spNpcData.makeEndTime = makeEndTime

        npcData.formulaSellId = sid
        _G.gluaFuncAutoUseFormula(player, pid, {[itemId] = 1}, {}, nil, {
            endTime = makeEndTime,
            sellId = sid,
            maxCnt = spNpcData.maxCnt
        })
    elseif npcType == specialNpcType.trade then
        spNpcData = npcData.tradeNpc[idx]
        npcData.tradeSellId = sid
    else
        local itemId = itemInfo.id
        local itemType = itemInfo.type
        if type == define.sellType.customerBuy or type == define.sellType.guide then
            if itemInfo.count <= 0 then
                print("ReqSetSellOrder count <= 0", pid)
                return
            end
        elseif type == define.sellType.workerItem then
            local itemNpc = npcData.itemNpc
            local mdata = itemNpc[idx]
            if not mdata then
                print("ReqSetSellOrder no mdata", pid)
                return
            end

            mdata.itemId = nil
            mdata.count = nil
            mdata.endTime = nil
            npcData.itemSellId = sid
        elseif type == define.sellType.selllEquip then
            local equipNpc = npcData.equipNpc
            local mdata = equipNpc[idx]
            if not mdata then
                print("ReqSetSellOrder no mdata", pid)
                return
            end

            mdata.endTime = nil
            mdata.itemId = nil
            npcData.equipSellId = sid
        else
            if itemInfo.type == define.itemType.equip then
                local cfg = equipConfig[itemId]
                if not cfg then
                    print("ReqSetSellOrder no find equip config", pid, itemId)
                    return
                end

                if cfg.equipQuality > define.equipQuality.white then
                    print("ReqSetSellOrder no rare equip", pid, itemId)
                    return
                end
            else
                if not itemConfig[itemId] then
                    print("ReqSetSellOrder no find item config", pid, itemId)
                    return
                end
            end
        end
    end

    saveNpcData(player)

    datas.sellTypeData = datas.sellTypeData or {}
    local sellTypeData = datas.sellTypeData

    datas.sellData = datas.sellData or {}
    local sellData = datas.sellData

    local stype = tostring(type)
    local typeData = sellTypeData[stype]

    sellData[sid] = {}
    local sd = sellData[sid]

    sd.characterId = charId
    sd.characterLv = charLv
    sd.talkType = G_EnumDefine.TALK_TYPE.NO
    sd.priceType = G_EnumDefine.PRICE_TYPE.NO
    sd.type = type
    sd.pos = pos
    sd.itemInfo = itemInfo
    sd.fuid = fuid
    sd.idx = idx
    sd.makeEndTime = spNpcData.makeEndTime or 0
    sd.makeCnt = spNpcData.makeCnt or 0
    sd.equipIds = spNpcData.equipIds or {}
    sd.npcType = npcType
    sd.maxCnt = spNpcData.maxCnt or 0

    datas.sellData = sellData

    spNpcData.endTime = nil
    spNpcData.equipIds = nil

    if not typeData then

        sellTypeData[stype] = {
            createCount = 0,
            createTime = nowTime
        }
        typeData = sellTypeData[stype]
    end

    typeData.createCount = typeData.createCount + 1

    saveData(player)

    local msgs = {}
    msgs.uid = uid
    msgs.sellData = packSellInfo(sid, sd)

    net.sendMsg2Client(player, ProtoDef.ResSetSellOrder.name, msgs)

end

local function getDealGetEnergy(player, pid, sellType, furnitureDatas)
    if sellType == define.sellType.customerBuy or sellType == define.sellType.customerSell or sellType ==
        define.sellType.guide then
        return 0
    else
        local max = bagsystem.getGoodWillMaxVal(player)
        local add = tonumber(constConfig["specialDelegateEnegy"].value)
        if max > 0 then
            return math.ceil(max * add)
        end
    end

    return 0
end

local function getEquipPrice(player, pid, equipId, cfg, priceType)
    if not cfg then
        print("getEquipPrice err", equipId)
        return 0
    end

    local basePrice = cfg.sellValue
    local val1 = _G.gluaFuncGetMilestoneGoldEffect(player, equipId)
    local val2 = _G.gluaFuncGetWorkShopEffect(player, define.MAP_TYPE.LION_OPEN)
    basePrice = basePrice + basePrice * ((val1 + val2) / 10000)

    if priceType == __EnumDefine.PRICE_TYPE.RISE then
        local val3 = _G.gluaFuncGetWorkShopEffect(player, define.MAP_TYPE.BARGAIN)
        local gainExp = tools.splitByNumber(constConfig["gainExp"].value, ",")
        basePrice = basePrice * (1 + gainExp[1] + val3 / 10000)

        tasksystem.updateProcess(player, pid, define.taskType.raiseAndSell, {1}, define.taskValType.add)
    elseif priceType == __EnumDefine.PRICE_TYPE.discount then
        local discount = tools.splitByNumber(constConfig["discount"].value, ",")
        basePrice = basePrice * (1 - discount[1])

        tasksystem.updateProcess(player, pid, define.taskType.disAndSell, {1}, define.taskValType.add)
    end

    return basePrice
end

local function sendShopSellData(player, code, stype, typeData, sellId, addGold, energyAddVal)
    local tempResult = {}
    tempResult.gold = tostring(addGold or 0)
    tempResult.energy = energyAddVal or 0
    tempResult.sellTypeData = packSellTypeInfo(stype, typeData)
    tempResult.sellId = sellId
    tempResult.code = code

    net.sendMsg2Client(player, ProtoDef.ResShopSell.name, tempResult)
end

local function getFrunEquipInfo(player, pid, furnitureList, uid, itemId, count)
    uid = uid or ""

    local data = furnitureList[uid]
    if not data then
        return
    end

    local heroType = define.itemType.hero
    local carriageType = define.itemType.carriage

    local furnType = define.itemType.furniture

    local list = {}
    local showData = data.showData
    for k, v in pairs(showData or {}) do
        local info = bagsystem.getItemInfo(player, pid, v) or {}

        if info.id == itemId then
            local owner = info.owner
            if not owner or info.ownerType ~= furnType then
                print("getFrunEquipInfo err", pid, uid)
                return false
            end

            table.insert(list, v)

        end
    end

    local addCnt = 0

    local ret = {}
    ret[itemId] = {}
    local retList = ret[itemId]

    for i = 1, count do
        local nowCnt = #list
        if nowCnt > 0 then
            local idx = math.random(1, nowCnt)
            table.insert(retList, list[idx])
            table.remove(list, idx)

            addCnt = addCnt + 1
        end

    end

    if addCnt ~= count then
        print("getFrunEquipInfo no enough", pid, uid)
        return false
    end

    return ret

end

local function ReqShopSell(player, pid, proto)
    local sellId = proto.sellId
    local datas = getData(player)
    if not datas then
        print("ReqShopSell no datas", pid, sellId)
        return
    end

    local sellData = datas.sellData
    if not sellData then
        print("ReqShopSell no sellData", pid, sellId)
        return
    end

    local sid = tostring(sellId)
    local theSellData = sellData[sid]

    if not theSellData then
        print("ReqShopSell no theSellData", pid, sellId)
        return
    end

    local sellTypeData = datas.sellTypeData
    if not sellTypeData then
        print("ReqShopSell no sellTypeData", pid, sellId)
        return
    end

    local info = theSellData.itemInfo
    local stype = tostring(theSellData.type)
    local typeData = sellTypeData[stype]
    if not typeData then
        print("ReqShopSell no typeData", pid, sellId)
        return
    end

    local itemId = info.id
    local itemCount = info.count
    local cnt = bagsystem.getItemCountByIdAndType(player, pid, itemId, info.type)
    if cnt <= 0 or cnt < itemCount then
        print("ReqShopSell no itemInfo", pid, sellId)
        return
    end

    local delItem = getFrunEquipInfo(player, pid, datas.furnitureList, theSellData.fuid, itemId, itemCount)
    if delItem == false then
        return
    end

    if delItem then
        bagsystem.deleteEquipByUid(player, pid, delItem, true)
    else
        local extra = {
            check = 1
        }
        bagsystem.costItems(player, {info}, extra)
        if extra.res then
            print("ReqShopSell no itemInfo", pid, sellId)
            return
        end
    end

    typeData.finishCount = (typeData.finishCount or 0) + 1
    typeData.finishTime = gTools:getNowTime()

    -- 获取金币、能量
    local furnitureList = datas.furnitureList or {}
    local energyAddVal = getDealGetEnergy(player, pid, theSellData.type, furnitureList)
    local addGold, addHeroCoin = 0, 0
    local price = theSellData.price or 0
    local id = info.id

    local equipCfg = equipConfig[id]
    if equipCfg and equipCfg.payGetEnergy then
        energyAddVal = energyAddVal + equipCfg.payGetEnergy
    end

    if theSellData.type == define.sellType.customerBuy or theSellData.type == define.sellType.guide then
        local finalPrice = getEquipPrice(player, pid, id, equipCfg, theSellData.priceType)
        addGold = math.ceil(finalPrice * math.abs(itemCount))

    elseif theSellData.type == define.sellType.heroBuy then
        addHeroCoin = {
            characterId = theSellData.characterId,
            price = price
        }

    elseif theSellData.type == define.sellType.princessBuy then
        local tempPrice = price
        addGold = tempPrice
    end


    local val = getGuitaiAddVal(datas)

    local expCnt = tonumber(constConfig["gainExp"] and constConfig["gainExp"].value or 1)
    local awards = 
    {
        {
            id = define.currencyType.gold,
            count = addGold,
            type = define.itemType.currency
        }, 
        {
            id = define.currencyType.goodWill,
            count = math.floor(energyAddVal * itemCount * val + energyAddVal),
            type = define.itemType.currency
        }, 
        {
            id = define.currencyType.ratingExp,
            count = math.ceil(expCnt * addGold),
            type = define.itemType.currency
        }
    }

    bagsystem.addItems(player, awards, define.rewardTypeDefine.notshow)
    sellData[sid] = nil
    saveData(player)

    sendShopSellData(player, msgCode.result.success, stype, typeData, sellId, addGold, energyAddVal)

    tasksystem.updateProcess(player, pid, define.taskType.comDisAndSell, {0, 1}, define.taskValType.add)

    if equipCfg then
        local kind = bagsystem.getEquipKind(equipCfg.portion)
        local pos = bagsystem.getEquipPos(equipCfg.portion)
        tasksystem.updateProcess(player, pid, define.taskType.sellEquipCnt, {itemCount}, define.taskValType.add,
            {equipCfg.equipQuality, kind, pos, id})
        tasksystem.updateProcess(player, pid, define.taskType.sellFixEquipCnt, {itemCount}, define.taskValType.add,
            {equipCfg.belong})
    end

    if addGold > 0 then
        tasksystem.updateProcess(player, pid, define.taskType.sale, {addGold}, define.taskValType.add)
    end
end

local function getProductionBuyPrice(id, type)
    local cfg = equipConfig[id] or {}
    if type == define.itemType.item then
        cfg = itemConfig[id]
    end

    return cfg.buyValue or 1
end

local function createFormulaNpcCallBack(player, idx)

end

local function createFormulaNpc(player, pid, curTime, npc, idx, timeIdx, randTime)
    npc[idx] = {
        idx = timeIdx
    }

    local eid = timerMgr.addTimer(player, randTime, createFormulaNpcCallBack, 0, idx)
    if not eid then
        print("createFormulaNpc err", pid)
        return
    end

    local info = npc[idx]

    local endTime = curTime + randTime
    info.endTime = endTime

end

local function createItemNpcCallBack(player, idx)
    local datas = getNpcData(player)
    if not datas then
        return
    end

    local itemNpc = datas.itemNpc
    if not itemNpc then
        return
    end

    local data = itemNpc[idx]
    if not data then
        return
    end

    local itemIdx = datas.itemIdx
    if itemIdx ~= idx then
        data.endTime = nil
        saveNpcData(player)
        return
    end

    local itemId = data.itemId or 0
    if itemId == 0 then
        local pid = player:getPid()
        furnituresystem.processSpecialNpc(player, pid, idx, define.sellType.workerItem)
        return
    end

    local count = data.count
    saveNpcData(player)

    local msgs = {
        data = {{
            idx = idx,
            type = define.sellType.workerItem,
            itemInfo = {
                id = itemId,
                count = count,
                type = define.itemType.item
            }
        }}
    }

    net.sendMsg2Client(player, ProtoDef.NotifySellOrder.name, msgs)
end

function furnituresystem.createItemNpc(player, pid, curTime, npc, idx, timeIdx, randTime, itemId, count)
    npc[idx] = {
        idx = timeIdx
    }

    local eid = timerMgr.addTimer(player, randTime, createItemNpcCallBack, 0, idx)
    if not eid then
        print("createItemNpc err", pid)
        return
    end

    local info = npc[idx]

    info.itemId = itemId
    info.count = count
    info.endTime = curTime + randTime
end

local function randNpcItemInfo(player, pid, cacheSpaceData)
    local itemCache = cacheSpaceData.itemCache or {}
    local orderPeople = tools.splitByNumber(constConfig.orderPeople.value, ",")
    local minRang = orderPeople[1]
    local maxRang = orderPeople[2]

    local randIds = {}
    local itemType = define.itemType.item
    for i = minRang, maxRang do
        local orderPeopleConf = orderPeopleConfig[i]
        if orderPeopleConf then
            local itemId = orderPeopleConf.sellMaterial
            local sid = tostring(itemId)
            local oldCnt = bagsystem.getItemCountByIdAndType(player, pid, itemId, itemType)
            local cnt = itemCache[sid] or 0
            if cnt > 0 and oldCnt < cnt then
                table.insert(randIds, {itemId, cnt})
            end
        end
    end

    return randIds
end

local function calcEquipId(player)
    local workerEquipQuality = constConfig.workerEquipQuality.value
    local ret = tools.splitByNumber(workerEquipQuality, ",")
    local quality = tools.ranomdQuality(ret)

    local workerEquipRank = constConfig.workerEquipRank.value

    ret = tools.splitByNumber(workerEquipRank, ",")

    local stepCfg = bagsystem.getEquipStepByQuality(quality)

    local tab = {}
    local level = player:getLevel()
    local maxStep = 0
    for k, v in pairs(ratingLevelUnlockConfig) do
        local effect = v.effect
        local needLv = v.parameter[1]
        if effect[1] == 1 and level >= needLv then -- 可以打造的阶级
            maxStep = effect[3]
        end
    end

    local minVal = maxStep - ret[1]
    if minVal <= 0 then
        minVal = 1
    end

    local maxVal = maxStep - ret[2]
    if maxVal < 2 then
        maxVal = 2
    end

    local list = {}
    for step, v in pairs(stepCfg) do
        if step >= minVal and step <= maxVal then
            tools.mergeRewardArr(list, v)
        end
    end

    local index = math.random(1, #list)
    local equipId = list[index]

    return equipId
end

local function createEquipNpcCallBack(player, idx)
    local datas = getNpcData(player)
    if not datas then
        return
    end

    local equipNpc = datas.equipNpc
    if not equipNpc then
        return
    end

    local data = equipNpc[idx]
    if not data then
        return
    end

    if datas.equipIdx ~= idx then
        data.endTime = nil
        saveNpcData(player)
        return
    end

    local equipId = calcEquipId(player)
    data.itemId = equipId

    saveNpcData(player)

    local msgs = {
        data = {{
            idx = idx,
            type = define.sellType.selllEquip,
            itemInfo = {
                id = equipId,
                count = 1,
                type = define.itemType.equip
            }
        }}
    }

    net.sendMsg2Client(player, ProtoDef.NotifySellOrder.name, msgs)
end

local function createEquipNpc(player, pid, curTime, npc, idx, timeIdx, randTime)
    npc[idx] = {
        idx = timeIdx
    }

    local eid = timerMgr.addTimer(player, randTime, createEquipNpcCallBack, 0, idx)
    if not eid then
        print("createEquipNpc err", pid)
        return
    end

    local info = npc[idx]

    local endTime = curTime + randTime
    info.endTime = endTime

end

function furnituresystem.processSpecialNpc(player, pid, idx, type)
    local curTime = gTools:getNowTime()
    local npcData = getNpcData(player)
    if type == define.sellType.workerItem then
        local itemNpc = npcData.itemNpc
        if not itemNpc then
            return
        end

        local cfg = orderWorkerMaterialConfig[idx]
        if not cfg then
            print("processSpecialNpc no cfg", pid, idx)
            return
        end

        local data = itemNpc[idx]
        if not data then
            print("processSpecialNpc no data", pid, idx)
            return
        end

        data.itemId = nil
        data.count = nil
        data.endTime = nil

        local nowIdx = npcData.itemIdx or 1
        local idxData = itemNpc[nowIdx]
        local timeIdx, randTime = getItemEquipNextTimeIdxAdnTime(cfg, nowIdx)

        data.idx = timeIdx
        npcData.itemSellId = nil

        local cacheSpaceData = getCacheSpaceData(player)
        local randIds = randNpcItemInfo(player, pid, cacheSpaceData)
        local nowLen = #randIds
        local itemId = 0
        local count = 0
        if nowLen > 0 then
            local index = math.random(1, nowLen)
            local rCountIndex = math.random(1, 2)
            local info = randIds[index]
            itemId = info[1]
            local cnt = info[2]
            count = math.floor(cnt * cfg.workerSellMaterialCount[rCountIndex])
        end

        furnituresystem.createItemNpc(player, pid, curTime, itemNpc, nowIdx, timeIdx, randTime, itemId, count)
        saveNpcData(player)
    elseif type == define.sellType.selllEquip then
        local equipNpc = npcData.equipNpc
        if not equipNpc then
            return
        end

        local cfg = orderWorkerEquipConfig[idx]
        if not cfg then
            print("processSpecialNpc no cfg", pid, idx)
            return
        end

        local data = equipNpc[idx]
        if not data then
            print("processSpecialNpc no data", pid, idx)
            return
        end

        data.itemId = nil
        data.endTime = nil

        local nowIdx = npcData.equipIdx
        local idxData = equipNpc[nowIdx]
        local timeIdx, randTime = getItemEquipNextTimeIdxAdnTime(cfg, idxData.idx)

        idxData.idx = timeIdx
        npcData.equipSellId = nil

        createEquipNpc(player, pid, curTime, equipNpc, nowIdx, timeIdx, randTime)

        saveNpcData(player)
    end

    return true
end

local function ReqShopBuy(player, pid, proto)
    local sellId = proto.sellId
    local datas = getData(player)
    if not datas then
        print("ReqShopBuy no datas", pid, sellId)
        return
    end

    local sellData = datas.sellData
    local sid = tostring(sellId)
    local theSellData = sellData and sellData[sid]

    if not theSellData then
        print("ReqShopBuy no theSellData", pid, sellId)
        return
    end

    local sellTypeData = datas.sellTypeData
    if not sellTypeData then
        print("ReqShopBuy no sellTypeData", pid, sellId)
        return
    end

    local type = theSellData.type
    local stype = tostring(type)
    local typeData = sellTypeData[stype]
    if not typeData then
        print("ReqShopBuy no typeData", pid, sellId)
        return
    end

    local info = theSellData.itemInfo or {}
    local count = info.count or 0
    local itemType = info.type
    local id = info.id
    if count <= 0 then
        print("ReqShopSell 0 count", pid, sellId)
        return
    end

    -- 获取金币、能量
    local furnitureList = datas.furnitureList or {}
    local energyAddVal = getDealGetEnergy(player, pid, type, furnitureList)
    local costGold = 0
    -- 获取金币、能量
    local priceFactor = 0
    local priceType = theSellData.priceType
    if priceType == __EnumDefine.PRICE_TYPE.NO then
        priceFactor = 1
    elseif priceType == __EnumDefine.PRICE_TYPE.RISE then
        priceFactor = 2
    elseif priceType == __EnumDefine.PRICE_TYPE.discount then
        priceFactor = 0.5
    end

    if itemType == define.itemType.equip then
        local equipCfg = equipConfig[id]
        if equipCfg and equipCfg.payGetEnergy then
            energyAddVal = energyAddVal + equipCfg.payGetEnergy
        end
    end

    costGold = math.ceil(getProductionBuyPrice(id, itemType) * priceFactor)

    if costGold > 0 then
        costGold = costGold * count
        if not bagsystem.checkAndCostItem(player, {{
            id = define.currencyType.gold,
            type = define.itemType.currency,
            count = costGold
        }}) then
            print("ReqShopSell not enougth", pid, sellId)
            return
        end
    end

    local awards = {{
        id = id,
        type = itemType,
        count = count
    }}
    if energyAddVal > 0 then
        table.insert(awards, {
            id = define.currencyType.goodWill,
            type = define.itemType.currency,
            count = energyAddVal
        })
    end

    bagsystem.addItems(player, awards, define.rewardTypeDefine.notshow)

    local idx = theSellData.idx

    local ret = true
    if type == define.sellType.workerItem or type == define.sellType.selllEquip then
        ret = furnituresystem.processSpecialNpc(player, pid, idx, type)
    end

    if ret ~= true then
        return
    end

    sellData[sid] = nil
    typeData.finishCount = (typeData.finishCount or 0) + 1
    typeData.finishTime = gTools:getNowTime()

    saveData(player)

    local tempResult = {}
    tempResult.energy = energyAddVal
    tempResult.sellTypeData = packSellTypeInfo(stype, typeData)
    tempResult.sellId = sellId

    net.sendMsg2Client(player, ProtoDef.ResShopBuy.name, tempResult)
end

local function ReqShopAdvise(player, pid, proto)
    local sellId = proto.sellId
    local datas = getData(player)
    if not datas then
        print("ReqShopAdvise no datas", pid, sellId)
        return
    end

    local sellData = datas.sellData
    if not sellData then
        print("ReqShopAdvise no sellData", pid, sellId)
        return
    end

    local sid = tostring(sellId)
    local theSellData = sellData[sid]

    if not theSellData then
        print("ReqShopAdvise no theSellData", pid, sellId)
        return
    end

    local itemInfo = bagsystem.getItemInfo(player, pid, theSellData.guid)
    if not itemInfo then
        print("ReqShopAdvise no itemInfo", pid, sellId)
        return
    end

    local theEquipConfig = equipConfig[itemInfo.id]
    if not theEquipConfig then
        print("ReqShopAdvise no theEquipConfig", pid, sellId)
        return
    end
    local effect = _G.gluaFuncGetFurnitureEffect(player)
    local cnt = theEquipConfig.adviseReduceEnergy - math.ceil(theEquipConfig.adviseReduceEnergy * effect.discountEnergy)
    if not bagsystem.checkAndCostItem(player, {{
        id = define.currencyType.goodWill,
        type = define.itemType.currency,
        count = cnt
    }}) then
        print("ReqShopAdvise no enougth", pid, sellId, cnt)
        return
    end

    theSellData.guid = proto.guid
    theSellData.count = proto.count
    theSellData.sellId = proto.sellId

    saveData(player)

    net.sendMsg2Client(player, ProtoDef.ResShopAdvise.name, proto)

    tasksystem.updateProcess(player, pid, define.taskType.equipRecommendation, {1}, define.taskValType.add)
end

local function ReqShopRefuse(player, pid, proto)
    local sellId = proto.sellId
    local datas = getData(player)
    if not datas then
        print("ReqShopRefuse no datas", pid, sellId)
        return
    end

    local sellData = datas.sellData
    if not sellData then
        print("ReqShopRefuse no sellData", pid, sellId)
        return
    end

    local sid = tostring(sellId)
    local theSellData = sellData[sid]


    if not theSellData then
        print("ReqShopRefuse no theSellData", pid, sellId)
        return
    end



    local sellTypeData = datas.sellTypeData
    if not sellTypeData then
        print("ReqShopRefuse no sellTypeData1", pid, sellId)
        return
    end

    local type = theSellData.type
    local stype = tostring(type)
    local typeData = sellTypeData[stype]
    if not typeData == nil then
        print("ReqShopRefuse no typeData", pid, sellId)
        return
    end

    local npcType = theSellData.npcType or 0
    local idx = theSellData.idx
    local ret = true
    if npcType == specialNpcType.trade then
        local npcData = getNpcData(player)
        if not datas then
            print("ReqShopRefuse no datas", pid, sellId)
            return
        end

        local tradeNpc = npcData.tradeNpc
        if not tradeNpc then
            print("ReqShopRefuse no tradeNpc", pid, sellId)
            return
        end

        local mdata = tradeNpc[idx]
        if not mdata then
            print("ReqShopRefuse no mdata", pid, sellId, idx)
            return
        end

        local curTime = gTools:getNowTime()
        local tradeIdx = npcData.tradeIdx
        local idxData = tradeNpc[tradeIdx]

        local conf = orderWorkerSpecialConfig[specialNpcType.trade]["npcType"][tradeIdx][1]
        local timeIdx, randTime = getNextTimeIdxAndTime(conf, idxData.idx)
        local endTime = curTime + randTime

        mdata.idx = timeIdx
        mdata.endTime = endTime
        mdata.equipIds = nil


        npcData.tradeSellId = nil

        sellData[sid] = nil

        if idx ~= tradeIdx then
            mdata.endTime = nil

            idxData.endTime = endTime
            idxData.idx = timeIdx
        end

        saveData(player)
        saveNpcData(player)
        net.sendMsg2Client(player, ProtoDef.ResNpcTrade.name, {
            sellId = sellId,
            endTime = endTime
        })

        print("ReqShopRefuse", pid, sellId)
        return
    elseif idx then
        ret = furnituresystem.processSpecialNpc(player, pid, idx, type)
    end

    if ret ~= true then
        return
    end



    local goodWill = theSellData.goodWill or 0
    local addEnergy = theSellData.addEnergy or 0
    local priceType = theSellData.priceType or 1
    local talkType = theSellData.talkType or 1
    local currenType = define.itemType.currency
    local currenId = define.currencyType.goodWill
    local show = define.rewardTypeDefine.notshow
    local tmpGooWill = goodWill

    if priceType == __EnumDefine.PRICE_TYPE.RISE or priceType == __EnumDefine.PRICE_TYPE.less then -- 减了善意值
        if talkType == __EnumDefine.TALK_TYPE.FAIL then -- 减了善意值
            goodWill = goodWill + addEnergy
        elseif talkType == __EnumDefine.TALK_TYPE.SUCCESS then
            goodWill = goodWill - addEnergy 
        end

        if goodWill < 0 then
            goodWill = math.abs(goodWill)
            if not bagsystem.checkAndCostItem(player, {{id = currenId, count = goodWill, type = currenType}}) then
                print("ReqShopRefuse goodWill < 0", pid, sellId, tmpGooWill, addEnergy, priceType, talkType)
                return
            end
        else
            if goodWill > 0 then
                bagsystem.addItems(player, {{id = currenId, count = goodWill, type = currenType}}, show)
            end
            
        end
    elseif priceType == __EnumDefine.PRICE_TYPE.discount or priceType == __EnumDefine.PRICE_TYPE.more then --加了善意值
        if talkType == __EnumDefine.TALK_TYPE.SUCCESS then -- 加了善意值
            goodWill = goodWill + addEnergy
        elseif talkType == __EnumDefine.TALK_TYPE.FAIL then
            if addEnergy > 0 then
                goodWill = addEnergy - goodWill 
                if goodWill > 0 then
                    bagsystem.addItems(player, {{id = currenId, count = goodWill, type = currenType}}, show)
                    goodWill = 0
                end
            end
        end

        goodWill = math.abs(goodWill)
        if goodWill > 0 then
            if not bagsystem.checkAndCostItem(player, {{id = currenId, count = goodWill, type = currenType}}) then
                print("ReqShopRefuse no enough", pid, sellId, tmpGooWill, addEnergy, priceType, talkType)
                return
            end
        end


    elseif talkType == __EnumDefine.TALK_TYPE.FAIL then
        if addEnergy > 0 then
            bagsystem.addItems(player, {{id = currenId, count = addEnergy, type = currenType}}, show)
        end
    elseif talkType == __EnumDefine.TALK_TYPE.SUCCESS then --加了善意值
        if addEnergy > 0 then
            if not bagsystem.checkAndCostItem(player, {{id = currenId, count = addEnergy, type = currenType}}) then
                return
            end
        end
    end

    sellData[sid] = nil

    typeData.finishCount = (sellTypeData.finishCount or 0) + 1
    typeData.finishTime = gTools:getNowTime()

    saveData(player)

    local msgs = {}
    msgs.sellId = sellId
    msgs.sellTypeData = packSellTypeInfo(stype, typeData)

    net.sendMsg2Client(player, ProtoDef.ResShopRefuse.name, msgs)

end

local function ReqShopPayMoreOrLess(player, pid, proto)
    local sellId, isPayMore = proto.sellId, proto.isPayMore
    local datas = getData(player)
    if not datas then
        print("ReqShopPayMoreOrLess no datas", pid, sellId)
        return
    end

    local sellData = datas.sellData
    if not sellData then
        print("ReqShopPayMoreOrLess no sellData", pid, sellId)
        return
    end

    local sid = tostring(sellId)
    local theSellData = sellData[sid]
    if not theSellData then
        print("ReqShopPayMoreOrLess no theSellData", pid, sellId)
        return
    end

    local priceType = theSellData.priceType
    if priceType ~= __EnumDefine.PRICE_TYPE.NO then
        print("ReqShopPayMoreOrLess type err", pid, sellId, theSellData.priceType)
        return
    end

    local itemInfo = theSellData.itemInfo
    if not itemInfo then
        print("ReqShopPayMoreOrLess no itemInfo", pid, sellId)
        return
    end

    local itemId = itemInfo.id
    local cfg = equipConfig[itemId]
    if not cfg then
        print("ReqShopPayMoreOrLess no equipConfig", pid, sellId)
        return
    end

    local energy = 0
    if isPayMore then
        local nowEnergy = bagsystem.getCurrencyNumById(player, define.currencyType.goodWill)
        local maxEnergy = bagsystem.getGoodWillMaxVal(player)
        local leftVal = maxEnergy - nowEnergy
        theSellData.priceType = __EnumDefine.PRICE_TYPE.more

        if leftVal > 0 then
            energy = getShopConsumeEnergyReduce(player, cfg.paymoreAddEnergy, itemId)

            if energy > 0 then
                energy = tools.getMinVal(leftVal, energy)
    
                local item = {id = define.currencyType.goodWill, type = define.itemType.currency, count = energy}
                bagsystem.addItems(player, {item}, define.rewardTypeDefine.notshow)
                theSellData.goodWill = energy
            end
        end

    else
        energy = getShopAddEnergyAdd(player, cfg.paylessReduceEnergy, itemId)
        if energy > 0 and not bagsystem.checkAndCostItem(player, {{
            id = define.currencyType.goodWill,
            type = define.itemType.currency,
            count = energy
        }}) then
            return
        end

        theSellData.priceType = __EnumDefine.PRICE_TYPE.less
        theSellData.goodWill = energy
    end

    saveData(player)

    net.sendMsg2Client(player, ProtoDef.ResShopPayMoreOrLess.name, {energy = energy})
end



local function ReqShopTalk(player, pid, proto)
    local sellId = proto.sellId
    local datas = getData(player)
    if not datas then
        print("ReqShopTalk no datas", pid, sellId)
        return
    end

    local sellData = datas.sellData
    if not sellData then
        print("ReqShopTalk no sellData", pid, sellId)
        return
    end

    local sid = tostring(sellId)
    local theSellData = sellData[sid]

    if not theSellData then
        print("ReqShopTalk no theSellData", pid, sellId)
        return
    end

    tasksystem.updateProcess(player, pid, define.taskType.talk, {1, 0}, define.taskValType.add)
    tasksystem.updateProcess(player, pid, define.taskType.comTalkAndRise, {1, 0}, define.taskValType.add)
    local effect = _G.gluaFuncGetFurnitureEffect(player)
    local talkCount = datas.talkCount or 0
    local nowEnergy = bagsystem.getCurrencyNumById(player, define.currencyType.goodWill)
    local maxEnergy = bagsystem.getGoodWillMaxVal(player)
    local leftVal = maxEnergy - nowEnergy
    local addEnergy = 0
    local chatSuccess = constConfig["chatProb"].value
    local ret = tools.splitByNumber(chatSuccess, ",")
    local trd = ret[1] + talkCount * ret[2] + (effect.talk / 10000)
    local rd = math.random()
    local isTalkSucc = rd < trd
    datas.talkCount = talkCount + 1

    local tempResult = {}
    -- 2.闲聊   80%成功率 20失败率（读const表）  成功获得（能力上限-当前能量）*10%+5  失败扣除当前能量*10%+5
    --isTalkSucc = false
    if isTalkSucc then
        theSellData.talkType = __EnumDefine.TALK_TYPE.SUCCESS
        datas.talkCount = 0

        if leftVal > 0 then
            -- 闲聊成功则获得
            addEnergy = math.ceil((maxEnergy - nowEnergy) * 0.1) + 5
            addEnergy = tools.getMinVal(leftVal, addEnergy)
            --addEnergy = 1
            local item = {
                id = define.currencyType.goodWill,
                count = addEnergy,
                type = define.itemType.currency
            }

            bagsystem.addItems(player, {item}, define.rewardTypeDefine.notshow)
            theSellData.addEnergy = addEnergy
        end
    else
        -- 失败则扣除
        theSellData.talkType = __EnumDefine.TALK_TYPE.FAIL
        if nowEnergy > 0 then
            addEnergy = math.ceil(nowEnergy * 0.1) + 5

            addEnergy = tools.getMinVal(nowEnergy, addEnergy)
            --addEnergy = 5
            bagsystem.costItems(player, {{
                id = define.currencyType.goodWill,
                count = addEnergy,
                type = define.itemType.currency
            }})

            theSellData.addEnergy = addEnergy
        end

    end

    saveData(player)

    local msgs = {}
    msgs.talkType = theSellData.talkType
    msgs.addEnergy = addEnergy
    msgs.sellId = sellId

    net.sendMsg2Client(player, ProtoDef.ResShopTalk.name, msgs)
end

local function getQuickCostBaseVal(player, resType, type, data)
    local val, totalTime = 0, 0
    local valKey = "quickCost" .. resType
    if type == define.shopTypeDef.production then
        local config = formulaConfig[data.id]
        val = config[valKey]
        if resType == "Energy" then
            val = getManufactureSPReduceEnergy(player, val, data.id)
        end
        val = val * data.totalTime / config.outputTime
        totalTime = data.totalTime
    elseif type == define.shopTypeDef.shopExtend then
        local config = shopConfig[0].shopUpgradeParam
        val = config[data][4]
        totalTime = config[data][6]
    elseif type == define.shopTypeDef.furnitureUp then
        local config = getFurnitureLevelup(data.id, data.level, true)
        val = config[valKey]
        totalTime = config.upgradeTime
    end
    return val / totalTime
end

local function ReqShopRiseOrDisCount(player, pid, proto)
    local sellId, isRise, isGuide = proto.sellId, proto.isRise, proto.isGuide

    local datas = getData(player)
    if not datas then
        print("ReqShopRiseOrDisCount no datas", pid, sellId)
        return
    end

    local sellData = datas.sellData
    if not sellData then
        print("ReqShopRiseOrDisCount no sellData", pid, sellId)
        return
    end

    local sid = tostring(sellId)
    local theSellData = sellData[sid]
    if not theSellData then
        print("ReqShopRiseOrDisCount no theSellData", pid, sellId)
        return
    end

    local info = theSellData.itemInfo
    if not info then
        print("ReqShopRiseOrDisCount no itemInfo", pid, sellId)
        return
    end

    local itemId = info.id
    local cfg = equipConfig[itemId]
    if not cfg then
        print("ReqShopRiseOrDisCount no cfg", pid, sellId, itemId)
        return
    end

    local priceType = theSellData.priceType
    if priceType ~= __EnumDefine.PRICE_TYPE.NO then
        print("ReqShopRiseOrDisCount type err", pid, sellId, theSellData.priceType)
        return
    end

    local itemCount = info.count or 1
    local priceEnergy = 0
    if isRise then
        priceType = __EnumDefine.PRICE_TYPE.RISE
        if not isGuide and info.type == define.itemType.equip then
            priceEnergy = getShopConsumeEnergyReduce(player, cfg.riseInPriceEnergy, itemId)
        end

        priceEnergy = priceEnergy * itemCount
        if priceEnergy > 0 and not bagsystem.checkAndCostItem(player, {{
            id = define.currencyType.goodWill,
            type = define.itemType.currency,
            count = priceEnergy
        }}) then
            return
        end

        tasksystem.updateProcess(player, pid, define.taskType.comTalkAndRise, {0, 1}, define.taskValType.add)
        tasksystem.updateProcess(player, pid, define.taskType.raiseOrDiscountCnt, {1}, define.taskValType.add, {0})

        theSellData.goodWill = priceEnergy
    else
        local nowEnergy = bagsystem.getCurrencyNumById(player, define.currencyType.goodWill)
        local maxEnergy = bagsystem.getGoodWillMaxVal(player)
        local leftVal = maxEnergy - nowEnergy
        priceType = __EnumDefine.PRICE_TYPE.discount

        if leftVal > 0 then
            if info.type == define.itemType.equip then
                priceEnergy = getShopAddEnergyAdd(player, cfg.discountEnergy, itemId)
            end
    
            if priceEnergy > 0 then
                priceEnergy = priceEnergy * itemCount
                priceEnergy = tools.getMinVal(leftVal, priceEnergy)
                bagsystem.addItems(player, {{
                    id = define.currencyType.goodWill,
                    type = define.itemType.currency,
                    count = priceEnergy
                }}, define.rewardTypeDefine.notshow)

                theSellData.goodWill = priceEnergy
    
    
            end
        end


        tasksystem.updateProcess(player, pid, define.taskType.comDisAndSell, {1, 0}, define.taskValType.add)
        tasksystem.updateProcess(player, pid, define.taskType.raiseOrDiscountCnt, {1}, define.taskValType.add, {1})
    end

    theSellData.priceType = priceType

    saveData(player)


    net.sendMsg2Client(player, ProtoDef.ResShopRiseOrDisCount.name, {energy = priceEnergy})

end

local function getEmptyStandPos(furnitureDatas)
    local sid = tostring(define.cashDeskId)
    local cashDeskData = furnitureDatas[sid] or {}
    local fu = getFurnitureLevelup(cashDeskData.id, cashDeskData.level)
    local maxPosCount = 0
    if fu and fu.capacity then
        maxPosCount = fu.capacity
    end

    local nowPosCount = 0
    local sellData = playerData:get("sellData")
    for _, v in ipairs(sellData) do
        if v.type == define.sellType.customerBuy or v.type == define.sellType.customerSell or v.type ==
            define.sellType.guide then
            nowPosCount = nowPosCount + 1
        end
    end
    return maxPosCount - nowPosCount
end


local function ReqExtendShop(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqExtendShop no datas", pid)
        return
    end

    local room = datas.room
    if not room then
        print("ReqExtendShop no room", pid)
        return
    end

    local id = proto.id
    local sid = tostring(id)

    if room[sid] then
        print("ReqExtendShop yet lock", pid)
        return
    end

    local currentRoomCount = 0
    for k, v in pairs(room) do
        currentRoomCount = currentRoomCount + 1
    end

    local currentShopUpgradeParam = shopConfig[0].shopUpgradeParam[currentRoomCount]
    if not currentShopUpgradeParam then
        print("ReqExtendShop no cfg", pid, id)
        return
    end

    local isGold = proto.isGold
    local nowTime = gTools:getNowTime()
    if isGold then
        local needLv = _G.gluaFuncGetRatingUnlock(player, define.ratingEfffect.formula, 0)
        if (currentRoomCount + 1) > needLv then
            print("ReqExtendShop no lv", pid, needLv, currentRoomCount)
            return
        end

        local costCnt = currentShopUpgradeParam[2]
        if not bagsystem.checkAndCostItem(player, {{
            id = define.currencyType.gold,
            count = costCnt,
            type = define.itemType.currency
        }}) then
            print("ReqExtendShop no gold", pid)
            return
        end

        local nowTime = gTools:getNowTime()
        room[sid] = {
            extendStartTime = nowTime,
            extendCompleteTime = nowTime + currentShopUpgradeParam[6]
        }

    else
        local costCnt = currentShopUpgradeParam[3]
        if not bagsystem.checkAndCostItem(player, {{
            id = define.currencyType.jade,
            count = costCnt,
            type = define.itemType.currency
        }}) then
            print("ReqExtendShop no ", pid)
            return
        end

        room[sid] = {}

        tasksystem.updateProcess(player, pid, define.taskType.extendShop, {1}, define.taskValType.add)
    end

    saveData(player)

    local tempResult = {}
    tempResult.updateRoomData = packRoom(id, room[sid])

    net.sendMsg2Client(player, ProtoDef.ResExtendShop.name, tempResult)
end

local function ReqCompleteExtendShop(player, pid, proto)
    local id = proto.id
    local datas = getData(player)
    if not datas then
        print("ReqCompleteExtendShop no datas", pid)
        return
    end

    local room = datas.room
    if not room then
        print("ReqCompleteExtendShop no room", pid)
        return
    end

    local sid = tostring(id)
    local roomData = room[sid]
    if not roomData then
        print("ReqCompleteExtendShop no roomData", pid, id)
        return
    end

    local currentRoomCount = 0
    for k, v in pairs(room) do
        currentRoomCount = currentRoomCount + 1
    end

    local nowTime = gTools:getNowTime()
    if proto.isUseGemQuick == true then
        local leftTime = roomData.extendCompleteTime - nowTime

        if leftTime > 0 then
            local costGem = math.ceil(getQuickCostBaseVal(player, "Gem", define.shopTypeDef.shopExtend,
                currentRoomCount - 1) * leftTime)
            costGem = costGem <= 0 and 1 or costGem

            if not bagsystem.checkAndCostItem(player, {{
                id = define.currencyType.jade,
                count = costGem,
                type = define.itemType.currency
            }}) then
                return
            end

        end
    else
        if nowTime < roomData.extendCompleteTime then
            print("ReqCompleteExtendShop no com", pid, id)
            return
        end
    end

    tools.cleanTableData(roomData)

    saveData(player)

    local tempResult = {}
    tempResult.updateRoomData = packRoom(id, {})
    net.sendMsg2Client(player, ProtoDef.ResCompleteExtendShop.name, tempResult)

    tasksystem.updateProcess(player, pid, define.taskType.extendShop, {1}, define.taskValType.add)
end

local function ReqBuyFurniture(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqCompleteExtendShop no datas", pid)
        return
    end

    local id = proto.id
    local cfg = furnitureConfig[id]
    if not cfg then
        print("ReqCompleteExtendShop no cfg", pid, id)
        return
    end

    local furnitureList = datas.furnitureList or {}
    local count = 0
    for _, theData in pairs(furnitureList) do
        if theData.id == id then
            count = count + 1
        end
    end

    local theFurniturePrice = cfg.price[count + 1]
    if not theFurniturePrice then
        theFurniturePrice = cfg.price[#cfg.price]
    end

    if theFurniturePrice[1] == define.currencyType.jade then
        local costGem = theFurniturePrice[2]
        if not bagsystem.checkAndCostItem(player, {{
            id = define.currencyType.jade,
            type = define.itemType.currency,
            count = costGem
        }}) then
            return
        end
    elseif theFurniturePrice[1] == define.currencyType.gold then
        local costGold = theFurniturePrice[2]
        if not bagsystem.checkAndCostItem(player, {{
            id = define.currencyType.gold,
            type = define.itemType.currency,
            count = costGold
        }}) then
            return
        end
    else
        print("ReqCompleteExtendShop no currency type", pid, id)
        return
    end

    local posInfo = {
        [id] = {
            minPos = proto.minPos,
            maxPos = proto.maxPos
        }
    }

    local extra = {}
    extra.furnitrurePos = posInfo
    extra.isFlip = proto.isFlip
    bagsystem.addItems(player, {{
        id = id,
        count = 1,
        type = define.itemType.furniture
    }}, define.rewardTypeDefine.notshow, nil, extra)

end

local function getFurnitureSlotByLevel(furniture_id, level)
    local fConfig = furnitureConfig[furniture_id]
    if #fConfig.goodsShelfData <= 0 then
        return 0
    end

    local levelToGridNum = fConfig.levelToGridNum
    local sl = 1
    for i, v in ipairs(levelToGridNum) do
        if v[1] <= level then
            sl = i
        end
    end

    local goodsShelfData = fConfig.goodsShelfData[1]
    return #goodsShelfData[sl]
end

local function addIdx(data)
    local config = furnitureConfig[data.id]
    if not config then
        print("addIdx furnitureConfig not find :", data.id)
        return
    end

    local goodsShelfData = config.goodsShelfData or {}
    if next(goodsShelfData) == nil then
        return
    end

    local levelToGridNum = config.levelToGridNum
    local nowIdx = data.nowIdx
    local maxCnt = #levelToGridNum
    if nowIdx >= maxCnt then
        return
    end

    local lv = data.level or 1
    local stage = 0
    local num = 0

    local idx = nil
    for i = 1, maxCnt do
        if nowIdx < i then
            local conf = levelToGridNum[i]
            local needLv = conf[1]
            if lv >= needLv then
                idx = i
                break
            end
        end
    end

    if idx then
        data.nowIdx = idx
        local idxCfg = goodsShelfData[idx]
        if idxCfg then
            local nowVal = data.nextId
            for k, v in pairs(idxCfg) do
                nowVal = nowVal + 1
                table.insert(data.useList, nowVal)
            end
            data.nextId = nowVal
        end
    end
end

local function ReqUpgradeFurniture(player, pid, proto)
    local guid, costType, minPos, maxPos = proto.guid, proto.costType, proto.minPos, proto.maxPos

    local datas = getData(player)
    if not datas then
        print("ReqUpgradeFurniture no datas", pid)
        return
    end

    local furnitureList = datas.furnitureList
    if not furnitureList then
        print("ReqUpgradeFurniture no furnitureList", pid)
        return
    end

    local sguid = tostring(guid)
    local furnitureData = furnitureList[sguid]
    if not furnitureData then
        print("ReqUpgradeFurniture no furnitureData", pid, guid)
        return
    end

    if furnitureData.upgradeCompleteTime then
        print("ReqUpgradeFurniture have upgradeCompleteTime", pid, guid)
        return
    end

    local furnitureId = furnitureData.id

    local fconf = furnitureConfig[furnitureId]
    if not fconf then
        print("ReqUpgradeFurniture no fconf", pid, furnitureId)
        return
    end

    local furniturelv = furnitureData.level or 1
    local costGem = 0
    local config = getFurnitureLevelup(furnitureId, furniturelv)
    if not config then
        print("ReqUpgradeFurniture not config", pid, guid)
        return
    end

    local nextLv = furniturelv + 1
    local nextCfg = getFurnitureLevelup(furnitureId, nextLv)
    if not nextCfg then
        print("ReqUpgradeFurniture not config", pid, guid)
        return
    end

    if costType == upLevelCostType.goldType then
        if config.costGold > 0 and not bagsystem.checkAndCostItem(player, {{
            id = define.currencyType.gold,
            count = config.costGold,
            type = define.itemType.currency
        }}) then
            return
        end

        local upgradeTime = config.upgradeTime
        local nowTime = gTools:getNowTime()

        furnitureData.upgradeStartTime = nowTime
        furnitureData.upgradeCompleteTime = nowTime + upgradeTime

    else
        local cost = {
            id = define.currencyType.jade,
            count = config.costGem,
            type = define.itemType.currency
        }

        if costType == upLevelCostType.fragmentType then
            cost = {
                id = config.fragment[1],
                count = config.fragment[2],
                type = define.itemType.item
            }
        end

        if not bagsystem.checkAndCostItem(player, {cost}) then
            return
        end

        local slot1 = getFurnitureSlotByLevel(furnitureId, furniturelv)
        furnitureData.level = nextLv
        furnitureData.minPos = minPos
        furnitureData.maxPos = maxPos

        addIdx(furnitureData)

        updateCacheSpaceData(player, pid, furnitureId, fconf, nil, config, nextCfg)
        saveCacheSpaceData(player)

        tasksystem.updateProcess(player, pid, define.taskType.furnitureLevelType, {1}, define.taskValType.add,
            {nextLv, fconf.type})

    end

    saveData(player)

    local msgs = {
        code = 1
    }
    msgs.furnitureUpdateData = packFurniture(guid, furnitureId, furnitureData)

    _G.CheckWorkShopFurnitureLv(player, pid, sguid, furnitureData.level)

    net.sendMsg2Client(player, ProtoDef.ResUpgradeFurniture.name, msgs)
end

local function ReqCompleteUpgradeFurniture(player, pid, proto)
    local guid, isUseGemQuick, minPos, maxPos, updateCustomerDatas = proto.guid, proto.isUseGemQuick, proto.minPos,
        proto.maxPos, proto.updateCustomerDatas

    local datas = getData(player)
    if not datas then
        print("ReqCompleteUpgradeFurniture no datas", pid)
        return
    end

    local furnitureList = datas.furnitureList
    if not furnitureList then
        print("ReqCompleteUpgradeFurniture no furnitureList", pid)
        return
    end

    local sguid = tostring(guid)
    local furnitureData = furnitureList[sguid]
    if not furnitureData then
        print("ReqCompleteUpgradeFurniture no furnitureData", pid, guid)
        return
    end

    local id = furnitureData.id

    local fconf = furnitureConfig[id]
    if not fconf then
        print("ReqCompleteUpgradeFurniture no fconf", pid, id)
        return
    end

    local level = furnitureData.level or 1

    local cfg = getFurnitureLevelup(id, level)
    if not furnitureData then
        print("ReqCompleteUpgradeFurniture no cfg", pid, level)
        return
    end

    local nextLv = level + 1
    local nextCfg = getFurnitureLevelup(id, nextLv)
    if not nextCfg then
        print("ReqCompleteUpgradeFurniture no nextCfg", pid, id, nextLv)
        return
    end

    local nowTime = gTools:getNowTime()

    local leftTime = (furnitureData.upgradeCompleteTime or 0) - nowTime
    if leftTime > 0 then
        local costGem = math.ceil(getQuickCostBaseVal(player, "Gem", define.shopTypeDef.furnitureUp, {
            id = id,
            level = level
        }) * leftTime)

        if not bagsystem.checkAndCostItem(player, {{
            id = define.currencyType.jade,
            type = define.itemType.currency,
            count = costGem
        }}) then
            return
        end
    end

    furnitureData.upgradeCompleteTime = nil
    furnitureData.upgradeStartTime = nil
    furnitureData.minPos = minPos
    furnitureData.maxPos = maxPos
    furnitureData.level = nextLv

    addIdx(furnitureData)

    updateCacheSpaceData(player, pid, id, fconf, nil, cfg, nextCfg)
    saveCacheSpaceData(player)

    local msgs = {
        code = 1
    }
    msgs.furnitureUpdateData = packFurniture(guid, id, furnitureData)
    net.sendMsg2Client(player, ProtoDef.ResCompleteUpgradeFurniture.name, msgs)

    tasksystem.updateProcess(player, pid, define.taskType.furnitureLevel, {nextLv}, define.taskValType.cover,
        {id, nextLv})

    tasksystem.updateProcess(player, pid, define.taskType.furnitureLevelType, {1}, define.taskValType.add,
        {nextLv, fconf.type})


    saveData(player)
end

local function ReqStoreFurniture(player, pid, proto)
    local guid = proto.guid
    local datas = getData(player)
    if not datas then
        print("ReqStoreFurniture no datas", pid)
        return
    end

    local furnitureList = datas.furnitureList
    if not furnitureList then
        print("ReqStoreFurniture no furnitureList", pid)
        return
    end

    local sguid = tostring(guid)
    local furnitureData = furnitureList[sguid]
    if not furnitureData then
        print("ReqStoreFurniture no furnitureData", pid, guid)
        return
    end

    if furnitureData.isStore then
        print("ReqStoreFurniture furnitureData isStore is true", pid, guid)
        return
    end

    local id = furnitureData.id
    local cfg = getFurnitureLevelup(id, furnitureData.level or 1)
    local cacheSpaceData = getCacheSpaceData(player)
    if cacheSpaceData and cfg then
        local ok1 = tools.isInArr(equipFurnitureList, id)
        local ok2 = tools.isInArr(itemFurnitureList, id)
        local itemCache = cacheSpaceData.itemCache

        if ok1 then
            local now = cacheSpaceData.equipSpace
            local cost = cfg.capacity
            if now < cost then
                print("ReqStoreFurniture no equipSpace1", pid, id, now, cost)
                return
            end

            cacheSpaceData.equipSpace = now - cost

            if id == chuwuxiangIdDef then
                now = cacheSpaceData.rareLeftSpace
                cost = cfg.param
                if now < cost then
                    print("ReqStoreFurniture no rareLeftSpace", pid, id, now, cost)
                    return
                end

                cacheSpaceData.rareLeftSpace = now - cost
            else
                local goodWill = tostring(define.currencyType.goodWill)
                now = itemCache[goodWill] or 0
                cost = cfg.param

                local left = now - cost
                if left <= 0 then
                    left = 0
                    bagsystem.costItems(player, {{
                        id = define.currencyType.goodWill,
                        type = define.itemType.currency,
                        count = cost
                    }})
                else
                    local val = bagsystem.getCurrencyNumById(player, goodWill)
                    if val > left then
                        bagsystem.costItems(player, {{
                            id = define.currencyType.goodWill,
                            type = define.itemType.currency,
                            count = val - left
                        }})
                    end
                end

                itemCache[goodWill] = left
            end
        end

        if ok2 then
            local conf = furnitureConfig[id]
            local itemId = conf.params[1][1]
            local sid = tostring(itemId)

            local leftCache = itemCache[sid] or 0
            if leftCache <= 0 then
                print("ReqStoreFurniture no leftCache", pid, id, itemId)
                return
            end

            local maxStack = itemCache[sid] or 0
            local cost = cfg.capacity

            local leftCache = maxStack - cost
            if leftCache <= 0 then
                leftCache = 0
            end

            local itemType = define.itemType.item
            local oldCnt = bagsystem.getItemCountByIdAndType(player, pid, itemId, itemType)
            if oldCnt > 0 then
                local subCnt = oldCnt
                subCnt = oldCnt - leftCache
                if subCnt > 0 then
                    bagsystem.costItems(player, {{
                        id = itemId,
                        count = subCnt,
                        typde = itemType
                    }})
                end
            end

            itemCache[sid] = leftCache
        end

        saveCacheSpaceData(player)
    end

    furnitureData.isStore = true

    local ok = false
    for k, v in pairs(furnitureData.showData or {}) do
        table.insert(furnitureData.useList, tonumber(k))
        local info = bagsystem.getItemInfo(player, pid, v)
        if info then
            info.owner = nil
            info.idx = nil
            info.ownerType = nil
            ok = true
        end
    end

    furnitureData.showData = {}

    if ok then
        playermoduledata.saveData(player, define.playerModuleDefine.bag)
    end

    saveData(player)

    net.sendMsg2Client(player, ProtoDef.ResStoreFurniture.name, {
        guid = guid
    })
end

local function ReqEditFurniture(player, pid, proto)
    local guid, isFlip, minPos, maxPos, updateCustomerDatas = proto.guid, proto.isFlip, proto.minPos, proto.maxPos,
        proto.updateCustomerDatas
    local datas = getData(player)
    if not datas then
        print("ReqEditFurniture no datas", pid)
        return
    end

    local furnitureList = datas.furnitureList
    if not furnitureList then
        print("ReqEditFurniture no furnitureList", pid)
        return
    end

    local sguid = tostring(guid)
    local furnitureData = furnitureList[sguid]
    if not furnitureData then
        print("ReqEditFurniture no furnitureData", pid, guid)
        return
    end

    local id = furnitureData.id

    local fconf = furnitureConfig[id]
    if not fconf then
        print("ReqEditFurniture no fconf", pid, id)
        return
    end

    furnitureData.minPos = minPos
    furnitureData.maxPos = maxPos
    furnitureData.isFlip = isFlip

    if furnitureData.isStore == true then
        local id = furnitureData.id
        local config = getFurnitureLevelup(id, furnitureData.level or 1)
        updateCacheSpaceData(player, pid, id, fconf, nil, config)

        furnitureData.isStore = false
    end

    saveData(player)

    local msgs = {}
    msgs.furnitureUpdateData = packFurniture(guid, furnitureData.id, furnitureData)
    net.sendMsg2Client(player, ProtoDef.ResEditFurniture.name, msgs)
end

local function ReqAddGoods(player, pid, proto)
    local guid, eid, position, opt = proto.guid, proto.eid, proto.position, proto.type
    local datas = getData(player)
    if not datas then
        print("ReqAddGoods no datas", pid)
        return
    end

    local furnitureList = datas.furnitureList
    if not furnitureList then
        print("ReqAddGoods no furnitureList", pid)
        return
    end

    local sguid = tostring(guid)
    local furnitureData = furnitureList[sguid]
    if not furnitureData then
        print("ReqAddGoods no furnitureData", pid, guid)
        return
    end

    local equpData = bagsystem.getItemInfo(player, pid, eid)
    if not equpData then
        print("ReqAddGoods no equpData", pid, eid)
        return
    end

    local cfg = equipConfig[equpData.id]
    if not cfg then
        print("ReqAddGoods no cfg", pid, eid)
        return
    end


    local useList = furnitureData.useList
    if not useList then
        print("ReqAddGoods no useList", pid, eid)
        return
    end

    local sposition = tostring(position)
    if opt == 0 then -- 放入
        if equpData.owner then
            print("ReqAddGoods have owner", pid, eid, equpData.owner)
            return
        end

        local idx = nil
        for k, v in pairs(useList) do
            if v == position then
                idx = k
                break
            end
        end

        furnitureData.showData = furnitureData.showData or {}
        local showData = furnitureData.showData
        if not idx then
            print("ReqAddGoods no pos", pid, eid, position)
            tools.ss(useList)
            tools.ss(showData)
            return
        end

        table.remove(useList, idx)
        showData[sposition] = eid

        equpData.owner = guid
        equpData.ownerType = define.itemType.furniture
        equpData.idx = position

    else -- 取回
        local showData = furnitureData.showData
        if not showData then
            print("ReqAddGoods no showData", pid, eid)
            return
        end

        if showData[sposition] == nil then
            print("ReqAddGoods no showData[sposition]", pid, eid)
            return
        end

        showData[sposition] = nil

        table.insert(useList, position)

        equpData.owner = nil
        equpData.ownerType = nil
        equpData.idx = nil

    end

    playermoduledata.saveData(player, define.playerModuleDefine.bag)

    saveData(player)

    local msgs = {}
    msgs.owner = guid
    msgs.eid = eid
    msgs.ownerType = define.itemType.furniture
    msgs.position = position

    net.sendMsg2Client(player, ProtoDef.ResAddGoods.name, msgs)
end

local function ReqChangeFloor(player, pid, proto)
    local id = proto.id
    local datas = getData(player)
    if not datas then
        print("ReqChangeFloor no datas", pid)
        return
    end

    local cfg = furnitureConfig[id]
    if not cfg then
        print("ReqChangeFloor furnitureConfig not find", pid, id)
        return
    end

    local costs = {}
    for k, v in pairs(cfg.price) do
        table.insert(costs, {
            id = v[1],
            count = v[2],
            type = define.itemType.currency
        })
    end

    if #costs > 0 and not bagsystem.checkAndCostItem(player, costs) then
        print("ReqChangeFloor cost not enough", pid, id)
        return
    end

    datas.floorId = id -- 当前id
    saveData(player)

    local msgs = {
        floorId = datas.floorId
    }

    net.sendMsg2Client(player, ProtoDef.ResChangeFloor.name, msgs)
end

local function AddNewSpecialNpc(player, pid, proto)
    local npcType, idx, itemInfo, equipIds, opt = proto.npcType, proto.idx, proto.itemInfo, proto.equipIds, proto.opt

    local datas = getNpcData(player)
    if not datas then
        return
    end

    local endTime = 0
    local curTime = gTools:getNowTime()
    local level = player:getLevel()

    if npcType == specialNpcType.formula then
        local formulaIdx = datas.formulaIdx
        if formulaIdx ~= idx then
            proto.endTime = curTime + 5
            itemInfo.id = 0
            print("AddNewSpecialNpc err0", pid, formulaIdx, idx)
            return
        end

        local cfg = orderWorkerSpecialConfig[npcType]["npcType"][idx][1]
        if not cfg then
            proto.endTime = curTime + 5
            itemInfo.id = 0
            print("AddNewSpecialNpc no cfg", pid)
            return
        end
    
        local data = nil

        if level < cfg.level then
            proto.endTime = curTime + 5
            itemInfo.id = 0
            print("AddNewSpecialNpc no enough level", pid, level, idx)
            return
        end

        local formulaSellId = datas.formulaSellId
        if formulaSellId then
            itemInfo.id = 0
            print("AddNewSpecialNpc err1", pid, formulaSellId)
            return
        end

        data = datas.formulaNpc

        local mdata = data[idx]
        if mdata.makeEndTime then
            itemInfo.id = 0
            print("ReqAddNewSpecialNpc have pre npc", pid)
            return
        end

        local itemId = itemInfo.id

        if itemId == 0 then
            local timeIdx, randTime = getNextTimeIdxAndTime(cfg, mdata.idx)
            endTime = curTime + randTime
            mdata.idx = timeIdx
            mdata.endTime = endTime
        else
            local conf = formulaConfig[itemId]
            if not conf then
                print("ReqAddNewSpecialNpc no cfg", pid, itemId)
                return
            end

            local itemCfg = itemConfig[itemId]
            if not itemCfg then
                print("ReqAddNewSpecialNpc no itemCfg", pid, itemId)
                return
            end

            if itemCfg.type ~= define.itemSubType.normalFormula then
                print("ReqAddNewSpecialNpc no normal formula", pid, itemId)
                return
            end

            local formulaData = playermoduledata.getData(player, define.playerModuleDefine.product) or {}
            local list = formulaData.list or {}
            local sid = tostring(itemId)
            local ldata = list[sid]
            if ldata then
                print("ReqAddNewSpecialNpc have this formula", pid, itemId)
                return
            end

            local sellTime = cfg.sellTime
            sellTime = sellTime[1]
            local randTime = math.random(sellTime[1], sellTime[2])
            randTime = 1
            endTime = curTime + randTime

            local range = tools.splitByNumber(constConfig.makeNumb.value, ",")
            local maxCnt = math.random(range[1], range[2])

            mdata.endTime = endTime
            mdata.itemId = itemId
            mdata.maxCnt = maxCnt
        end
    elseif npcType == specialNpcType.trade then
        local tradeIdx = datas.tradeIdx
        if tradeIdx ~= idx then
            proto.endTime = curTime + 5
            proto.equipIds = {}
            print("AddNewSpecialNpc err0", pid, tradeIdx, idx)
            return
        end

        local cfg = orderWorkerSpecialConfig[npcType]["npcType"][tradeIdx][1]
        if not cfg then
            proto.endTime = curTime + 5
            proto.equipIds = {}
            print("AddNewSpecialNpc no cfg", pid)
            return
        end
    
        local data = nil

        if level < cfg.level then
            proto.endTime = curTime + 5
            proto.equipIds = {}
            print("AddNewSpecialNpc no enough level", pid, level, idx)
            return
        end

        local tradeSellId = datas.tradeSellId
        if tradeSellId then
            proto.equipIds = {}
            print("AddNewSpecialNpc err2", pid, tradeSellId)
            return
        end

        data = datas.tradeNpc

        local mdata = data[idx]
        if next(equipIds) == nil then
            local timeIdx, randTime = getNextTimeIdxAndTime(cfg, mdata.idx)
            endTime = curTime + randTime
            mdata.endTime = endTime
            mdata.idx = timeIdx
        else
            local sellTime = cfg.sellTime
            sellTime = sellTime[1]
            local randTime = math.random(sellTime[1], sellTime[2])
            randTime = 1
            endTime = curTime + randTime

            mdata.equipIds = equipIds
            mdata.endTime = endTime
        end
    else
        print("ReqAddNewSpecialNpc no npc", pid, npcType)
        return
    end

    saveNpcData(player)

    proto.endTime = endTime


end

local function ReqAddNewSpecialNpc(player, pid, proto)

    for k, v in pairs(proto.data) do
        AddNewSpecialNpc(player, pid, v)
    end

    net.sendMsg2Client(player, ProtoDef.ResAddNewSpecialNpc.name, proto)
end

local function ReqMakeEquipNpcLeave(player, pid, proto)
    local sellId = proto.sellId

    local datas = getData(player)
    if not datas then
        print("ReqMakeEquipNpcLeave no datas", pid)
        return
    end

    local npcData = getNpcData(player)
    if not npcData then
        print("ReqMakeEquipNpcLeave no npcData", pid)
        return
    end

    local sellData = datas.sellData
    local sid = tostring(sellId)
    local theSellData = sellData[sid]
    if not theSellData then
        print("ReqMakeEquipNpcLeave no theSellData", pid, sellId)
        net.sendMsg2Client(player, ProtoDef.ResMakeEquipNpcLeave.name, {
            sellId = sellId,
            code = 1
        })
        return
    end

    local idx = theSellData.idx
    local formulaNpc = npcData.formulaNpc
    local data = formulaNpc[idx]
    if not data then
        print("ReqMakeEquipNpcLeave no mNpcData", pid, sellId, idx)
        return
    end

    local curTime = gTools:getNowTime()
    local opt = proto.opt
    if opt == 0 then
        local leftTime = data.makeEndTime - curTime
        if leftTime > 2 then
            print("ReqMakeEquipNpcLeave have leftTime", pid, sellId, idx)
            return
        end
    end

    local formulaIdx = npcData.formulaIdx
    local idxData = formulaNpc[formulaIdx]

    local conf = orderWorkerSpecialConfig[specialNpcType.formula]["npcType"][formulaIdx][1]
    local curTime = gTools:getNowTime()
    local timeIdx, randTime = getNextTimeIdxAndTime(conf, idxData.idx)
    local endTime = curTime + randTime

    local itemId = data.itemId

    data.endTime = endTime
    data.idx = timeIdx

    data.itemId = nil
    data.sellId = nil
    data.makeEndTime = nil
    data.maxCnt = nil

    npcData.formulaSellId = nil

    sellData[sid] = nil

    if idx ~= formulaIdx then
        data.endTime = nil

        idxData.endTime = endTime
        idxData.idx = timeIdx
    end

    saveData(player)

    saveNpcData(player)

    net.sendMsg2Client(player, ProtoDef.ResMakeEquipNpcLeave.name, {
        sellId = sellId,
        endTime = endTime
    })

    _G.gluaFuncUpdateTmpFormulaData(player, pid, itemId)

    print("ReqMakeEquipNpcLeave", pid, sellId)
end

local function ReqNpcTrade(player, pid, proto)
    local sellId, eid = proto.sellId, proto.eid
    local datas = getData(player)
    if not datas then
        print("ReqNpcTrade no datas", pid, sellId)
        return
    end

    local npcData = getNpcData(player)
    if not datas then
        print("ReqNpcTrade no datas", pid, sellId)
        return
    end

    local tradeNpc = npcData.tradeNpc
    if not tradeNpc then
        print("ReqNpcTrade no tradeNpc", pid, sellId)
        return
    end

    local sellData = datas.sellData
    local sid = tostring(sellId)
    local theSellData = sellData and sellData[sid]
    if not theSellData then
        print("ReqNpcTrade no theSellData", pid, sellId)
        return
    end

    local idx = theSellData.idx
    local mdata = tradeNpc[idx]
    if not mdata then
        print("ReqNpcTrade no mdata", pid, sellId, idx)
        return
    end

    local equip = bagsystem.getItemInfo(player, pid, eid)
    if not equip then
        print("ReqNpcTrade no equip", pid, sellId, idx)
        return
    end

    if equip.owner and equip.ownerType ~= define.itemType.furniture then
        print("ReqNpcTrade have master", pid, sellId, idx)
        return
    end

    local dels = {}
    local equipId = equip.id
    local cfg = equipConfig[equipId]
    if not cfg then
        print("ReqNpcTrade no cfg", pid, sellId, idx, equipId)
        return
    end

    dels[equipId] = {eid}

    local quality = cfg.equipQuality
    if quality == define.equipQuality.white then
        print("ReqNpcTrade no match quality", pid, sellId, idx, equipId)
        return
    end

    local tab = tools.splitByNumber(constConfig.upgradeChance.value, ",")
    local ret = {}
    local maxWeight = 0
    for k, v in ipairs(tab) do
        maxWeight = maxWeight + v
        table.insert(ret, maxWeight)
    end

    local sequipId = tostring(equipId)
    local first = tonumber(sequipId:sub(1, 1))
    local left = sequipId:sub(2)
    local rval = math.random(1, maxWeight)
    local maxQuality = define.equipQuality.orange
    for k, v in ipairs(ret) do
        if rval <= v then
            if k == 1 then -- 品质降低
                first = first - 1
                sequipId = first .. left
            elseif k == 3 then -- 品质提升
                first = first + 1
                if first > maxQuality then
                    first = maxQuality
                end

                sequipId = first .. left

            end
            break
        end
    end

    equipId = tonumber(sequipId)
    cfg = equipConfig[equipId]
    if not cfg then
        print("ReqNpcTrade no cfg", pid, sellId, idx, equipId)
        return
    end

    bagsystem.deleteEquipByUid(player, pid, dels)

    bagsystem.addItems(player, {{
        id = equipId,
        count = 1,
        type = define.itemType.equip
    }})

    local curTime = gTools:getNowTime()
    local tradeIdx = npcData.tradeIdx
    local idxData = tradeNpc[tradeIdx]

    local conf = orderWorkerSpecialConfig[specialNpcType.trade]["npcType"][tradeIdx][1]
    local timeIdx, randTime = getNextTimeIdxAndTime(conf, idxData.idx)
    local endTime = curTime + randTime

    mdata.idx = timeIdx
    mdata.endTime = endTime
    mdata.equipIds = nil

    npcData.tradeSellId = nil

    sellData[sid] = nil

    if idx ~= tradeIdx then
        mdata.endTime = nil

        idxData.endTime = endTime
        idxData.idx = timeIdx
    end

    saveData(player)
    saveNpcData(player)

    net.sendMsg2Client(player, ProtoDef.ResNpcTrade.name, {
        sellId = sellId,
        endTime = endTime
    })
    print("ReqNpcTrade", pid, sellId)
end

local function playerLevelChange(player, pid, oldLevel, nowLevel)
    local datas = getNpcData(player)
    if not datas then
        return
    end

    local curTime = gTools:getNowTime()
    local equipNpc = datas.equipNpc

    local cfgCnt = #orderWorkerEquipConfig
    local equipIdx = datas.equipIdx or 0
    if equipIdx < cfgCnt then
        for i = cfgCnt, 1, -1 do
            local cfg = orderWorkerEquipConfig[i]
            local cfgLv = cfg.level
            if nowLevel >= cfgLv then
                datas.equipIdx = i

                if equipIdx == i then
                    break
                end

                if not datas.equipSellId then
                    local sellTime = cfg.sellTime[1]
                    local randTime = math.random(sellTime[1], sellTime[2])
                    randTime = 1
                    createEquipNpc(player, pid, curTime, equipNpc, i, 1, randTime)
                end

                break
            end
        end
    end

    local cacheSpaceData = getCacheSpaceData(player)
    if cacheSpaceData then
        local itemNpc = datas.itemNpc
        cfgCnt = #orderWorkerMaterialConfig
        local itemIdx = datas.itemIdx or 0

        if itemIdx < cfgCnt then
            local randIds = randNpcItemInfo(player, pid, cacheSpaceData)
            local nowLen = #randIds
            for i = cfgCnt, 1, -1 do
                local cfg = orderWorkerMaterialConfig[i]
                local cfgLv = cfg.level
                if nowLevel >= cfgLv then
                    datas.itemIdx = i

                    if itemIdx == i then
                        break
                    end

                    if not datas.itemSellId then
                        if nowLen > 0 then
                            local index = math.random(1, nowLen)
                            local rCountIndex = math.random(1, 2)

                            local info = randIds[index]
                            local itemId = info[1]
                            local cnt = info[2]
                            local count = math.floor(cnt * cfg.workerSellMaterialCount[rCountIndex])

                            furnituresystem.createItemNpc(player, pid, curTime, itemNpc, i, 1, 1, itemId, count)
                        else

                            furnituresystem.createItemNpc(player, pid, curTime, itemNpc, i, 1, 1, 0, 0)
                        end
                    end
                    break
                end
            end
        end
    end

    for k, v in pairs(orderWorkerSpecialConfig) do
        local idx = 0
        local npcTypeCfg = v.npcType
        local maxIdx = #npcTypeCfg
        if k == specialNpcType.formula then
            idx = datas.formulaIdx or 0
        elseif k == specialNpcType.trade then
            idx = datas.tradeIdx or 0
        end

        local tmpIdx = idx
        if idx < maxIdx then
            for i = maxIdx, 1, -1 do
                local data = npcTypeCfg[i][1]
                if nowLevel >= data.level and idx ~= i then
                    idx = i
                    break
                end
            end
        end

        if idx > 0 and tmpIdx ~= idx then
            if k == specialNpcType.formula then
                datas.formulaIdx = idx
            elseif k == specialNpcType.trade then
                datas.tradeIdx = idx
            end
        end
    end

    saveNpcData(player)
end

local function login(player, pid, curTime, isfirst)
    local npcData = getNpcData(player)
    local datas = getData(player)
    local tmpData = getTmpData(pid)
    if not npcData or not datas or not tmpData then
        return
    end

    if isfirst then
        npcData.equipNpc = {}
        npcData.itemNpc = {}
        npcData.formulaNpc = {}
        npcData.tradeNpc = {}

        for k, v in ipairs(orderWorkerEquipConfig) do
            npcData.equipNpc[k] = {
                idx = 1
            }
        end

        for k, v in ipairs(orderWorkerMaterialConfig) do
            npcData.itemNpc[k] = {
                idx = 1
            }
        end

        for k, v in pairs(orderWorkerSpecialConfig) do
            if k == specialNpcType.formula then
                for idx, _ in pairs(v.npcType) do
                    npcData.formulaNpc[idx] = {
                        idx = 1
                    }
                end
            elseif k == specialNpcType.trade then
                for idx, _ in pairs(v.npcType) do
                    npcData.tradeNpc[idx] = {
                        idx = 1
                    }
                end
            end
        end
    end

    local curTime = gTools:getNowTime()
    local equipNpc = npcData.equipNpc
    local itemNpc = npcData.itemNpc
    local formulaNpc = npcData.formulaNpc
    local tradeNpc = npcData.tradeNpc

    tmpData.comNpc = {}
    local comNpc = tmpData.comNpc

    local itemType = define.itemType.item
    local equipType = define.itemType.equip

    local equipIdx = npcData.equipIdx
    if equipIdx and npcData.equipSellId == nil then

        local data = equipNpc[equipIdx]
        local endTime = data.endTime
        if endTime then
            local leftTime = curTime - endTime
            if leftTime < 0 then
                leftTime = math.abs(leftTime)
                timerMgr.addTimer(player, leftTime, createEquipNpcCallBack, 0, equipIdx)
            else
                local itemId = data.itemId or 0
                if itemId == 0 then
                    itemId = calcEquipId(player)
                    data.itemId = itemId
                end

                table.insert(comNpc, {
                    idx = equipIdx,
                    type = define.sellType.selllEquip,
                    itemInfo = {
                        id = itemId,
                        count = 1,
                        type = equipType
                    }
                })
            end
        end
    end

    local itemIdx = npcData.itemIdx
    if itemIdx and npcData.itemSellId == nil then
        local data = itemNpc[itemIdx]
        local endTime = data.endTime
        if endTime then
            local leftTime = curTime - endTime
            if leftTime < 0 then
                leftTime = math.abs(leftTime)
                timerMgr.addTimer(player, leftTime, createItemNpcCallBack, 0, itemIdx)
            else
                local itemId = data.itemId or 0
                if itemId == 0 then
                    local cacheSpaceData = getCacheSpaceData(player)
                    local randIds = randNpcItemInfo(player, pid, cacheSpaceData)
                    local nowLen = #randIds
                    local itemId = 0
                    local count = 0
                    if nowLen > 0 then
                        local cfg = orderWorkerMaterialConfig[itemIdx]
                        local index = math.random(1, nowLen)
                        local rCountIndex = math.random(1, 2)
                        local info = randIds[index]
                        itemId = info[1]
                        local cnt = info[2]
                        count = math.floor(cnt * cfg.workerSellMaterialCount[rCountIndex])
                        data.itemId = itemId
                        data.count = count

                        table.insert(comNpc, {
                            idx = itemIdx,
                            type = define.sellType.workerItem,
                            itemInfo = {
                                id = itemId,
                                count = data.count,
                                type = itemType
                            }
                        })
                    else
                        furnituresystem.createItemNpc(player, pid, curTime, itemNpc, itemIdx, data.idx, 1, 0, 0)
                    end
                else
                    table.insert(comNpc, {
                        idx = itemIdx,
                        type = define.sellType.workerItem,
                        itemInfo = {
                            id = itemId,
                            count = data.count,
                            type = itemType
                        }
                    })
                end

            end
        end
    end

    local sellData = datas.sellData
    local conf = orderWorkerSpecialConfig[specialNpcType.formula]["npcType"]

    local formulaIdx = npcData.formulaIdx
    if formulaIdx then
        local idxData = formulaNpc[formulaIdx]
        for idx, v in pairs(formulaNpc) do
            local makeEndTime = v.makeEndTime
            if makeEndTime and curTime >= makeEndTime then
                local sid = npcData.formulaSellId
                if sid then
                    sellData[sid] = nil
                end
                
                npcData.formulaSellId = nil

                _G.gluaFuncUpdateTmpFormulaData(player, pid, v.itemId)



                local cfg = conf[formulaIdx][1]
                local timeIdx, randTime = getNextTimeIdxAndTime(cfg, idxData.idx)
                local endTime = curTime + randTime

                v.endTime = endTime
                v.idx = timeIdx
                
                v.itemId = nil
                v.makeEndTime = nil

                if idx ~= formulaIdx then
                    v.endTime = nil

                    idxData.endTime = endTime
                    idxData.idx = timeIdx
                end
                break
            end
        end

        local endTime = idxData.endTime
        if (not endTime and (not npcData.formulaSellId)) or endTime then
            if not endTime then
                local cfg = conf[formulaIdx][1]
                local timeIdx, randTime = getNextTimeIdxAndTime(cfg, idxData.idx)
                endTime = curTime + randTime
                idxData.endTime = endTime
                idxData.idx = timeIdx
            end

            local info = {
                idx = formulaIdx,
                type = define.sellType.fouluma,
                endTime = endTime
            }
            if idxData.itemId then
                info.itemInfo = {
                    id = idxData.itemId,
                    count = 1,
                    type = itemType
                }
            end

            table.insert(comNpc, info)
        end
    end

    local tradeIdx = npcData.tradeIdx
    if tradeIdx then
        local tradeIdxData = tradeNpc[tradeIdx]
        local endTime = tradeIdxData.endTime
        if (not endTime and (not npcData.tradeSellId)) or endTime then
            if not endTime then
                local cfg = conf[tradeIdx][1]
                local timeIdx, randTime = getNextTimeIdxAndTime(cfg, tradeIdxData.idx)
                endTime = curTime + randTime
                tradeIdxData.endTime = endTime
                tradeIdxData.idx = timeIdx
            end

            local info = {
                idx = tradeIdx,
                type = define.sellType.trade,
                endTime = endTime
            }
            info.equipIds = tradeIdxData.equipIds or {}

            table.insert(comNpc, info)
        end
    end

    saveData(player)
    saveNpcData(player)
end

local function DeleteFurnEquip(player, furnList)
    local datas = getData(player)
    if not datas then
        return
    end

    local furnitureList = datas.furnitureList or {}
    local ok = false

    for fuid, uids in pairs(furnList) do
        local data = furnitureList[fuid]
        if data then
            local useList = data.useList
            local showData = data.showData

            for _, uid in pairs(uids) do
                for idx, eid in pairs(showData) do
                    if eid == uid then
                        table.insert(useList, tonumber(idx))
                        showData[idx] = nil
                        ok = true
                        break
                    end
                end
            end
        end
    end

    if ok then
        saveData(player)
    end
end

local function testNpcCallBack1(player, pid, args)
    pid = 3518438940707328069
    player = gPlayerMgr:getPlayerById(pid)
    createEquipNpcCallBack(player, 1)
end

local function cleannpcdata(player, pid, args)
    pid = 72100842323973
    player = gPlayerMgr:getPlayerById(pid)
    local datas = getNpcData(player)
    datas.itemNpc = nil
    saveNpcData(player)
end

local function showFurndata(player, pid, args)
    pid = 72104271011928
    player = gPlayerMgr:getPlayerById(pid)
    local datas = getCacheSpaceData(player)
    print(datas)
end

local function cleanFurnEquip(player, pid, args)
    pid = args[1]
    player = gPlayerMgr:getPlayerById(pid)

    for k, v in pairs(playermoduledata.getData(player, define.playerModuleDefine.bag)) do
        if v.type == define.itemType.equip and v.owner and v.ownerType == define.itemType.furniture then
            v.owner = nil
            v.ownerType = nil
            v.idx = nil
        end
    end

    playermoduledata.saveData(player, define.playerModuleDefine.bag)

    local datas = getData(player)
    for k, v in pairs(datas.furnitureList) do
        if v.nextId then
            v.useList = {}
            for i = 1, v.nextId do
                table.insert(v.useList, i)
            end

            v.showData = {}
        end
    end

    saveData(player)
end

local function UpdateFormulaNpcData(player, pid, sid, count)
    local datas = getData(player)
    if not datas then
        return
    end

    local sellData = datas.sellData
    local theSellData = sellData and sellData[sid]
    if not theSellData then
        print("UpdateFormulaNpcData no theSellData", pid, sid)
        return
    end

    local npcData = getNpcData(player)
    if not npcData then
        print("UpdateFormulaNpcData no npcData", pid)
        return
    end

    local idx = theSellData.idx
    local data = npcData.formulaNpc
    local mNpcData = data[idx]
    if not mNpcData then
        print("UpdateFormulaNpcData no mNpcData", pid, sid, idx)
        return
    end

    local makeCnt = theSellData.makeCnt or 0
    makeCnt = makeCnt + count
    local endTime = 0
    local maxCnt = theSellData.maxCnt
    theSellData.makeCnt = makeCnt

    local ret = false
    if makeCnt >= maxCnt then
        local idx = theSellData.idx

        local formulaIdx = npcData.formulaIdx
        local idxData = data[formulaIdx]

        local conf = orderWorkerSpecialConfig[specialNpcType.formula]["npcType"][formulaIdx][1]
        local curTime = gTools:getNowTime()
        local timeIdx, randTime = getNextTimeIdxAndTime(conf, idxData.idx)
        endTime = curTime + randTime

        mNpcData.endTime = endTime
        mNpcData.idx = timeIdx

        mNpcData.itemId = nil
        mNpcData.sellId = nil
        mNpcData.makeEndTime = nil

        sellData[sid] = nil

        npcData.formulaSellId = nil

        if idx ~= formulaIdx then
            mNpcData.endTime = nil

            idxData.endTime = endTime
            idxData.idx = timeIdx
        end

        ret = true

        print("UpdateFormulaNpcData", pid, sid)
    end

    saveData(player)

    saveNpcData(player)

    local npcMsg = {}
    npcMsg.sellId = sid
    npcMsg.cnt = makeCnt
    npcMsg.endTime = endTime

    net.sendMsg2Client(player, ProtoDef.NotifySpecialNpcData.name, npcMsg)

    return ret
end

local function ChangeFurnitureItem(player, furnList, items, currencyRd)
    local datas = getData(player)
    if not datas then
        return
    end

    local haveList = tools.clone(datas.haveList or {})
    for id, cnt in pairs(furnList) do
        local cfg = furnitureConfig[id] 
        local numb = cfg.numb or {}
        if next(numb) then

            local sid = tostring(id)
            local data = haveList[sid]

            local lens = #numb
            if not data then
                haveList[sid] = 1
                furnList[id] = 1
                cnt = cnt - 1

                if cnt > 0 then
                    if lens >= 2 then
                        local count = numb[2]
                        if count > 0 then
                            local cid = numb[1]
                            if cid > define.currencyType.none and cid < define.currencyType.max then -- 奖励为货币时
                                currencyRd[cid] = (currencyRd[cid] or 0) + count * cnt
                            else
                                items[cid] = (items[cid] or 0) + count * cnt
                            end
                        end
                    end
                end
            else
                if lens >= 2 then
                    local count = numb[2]
                    if count > 0 then
                        local cid = numb[1]
                        if cid > define.currencyType.none and cid < define.currencyType.max then 
                            currencyRd[cid] = (currencyRd[cid] or 0) + count * cnt
                        else
                            items[cid] = (items[cid] or 0) + count * cnt
                        end
                    end
                end
                furnList[id] = nil
            end

        end
    end
end

local function gmReqNpcData(player, pid, args)
    pid = 72103235023467
    player = gPlayerMgr:getPlayerById(pid)
    ReqNpcData(player, pid)
end

local function gmReqAddNewSpecialNpc(player, pid, args)
    pid = 72103230827817
    player = gPlayerMgr:getPlayerById(pid)
    ReqAddNewSpecialNpc(player, pid, {
        data = {
            [1] = {
                npcType = 2,
                idx = 1,
                equipIds = {},
                endTime = 0
            }
        }
    })
end

local function gmFurnLogin(player, pid, args)
    pid = 72103235023467
    player = gPlayerMgr:getPlayerById(pid)
    local curTime = gTools:getNowTime()
    login(player, pid, curTime, false)
end

_G.gluaFuncAddFurnitures = AddFurnitures
_G.gluaFuncgetManufactureSPReduceEnergy = getManufactureSPReduceEnergy
_G.gluaFuncgetQuickCostBaseVal = getQuickCostBaseVal
_G.gluaFuncDeleteFurnEquip = DeleteFurnEquip
_G.gluaFuncUpdateFormulaNpcData = UpdateFormulaNpcData
_G.gluaFuncChangeFurnitureItem = ChangeFurnitureItem

event.reg(event.eventType.playerLevel, playerLevelChange)
event.reg(event.eventType.login, login)

gm.reg("testNpcCallBack1", testNpcCallBack1)
gm.reg("cleannpcdata", cleannpcdata)
gm.reg("showFurndata", showFurndata)
gm.reg("cleanFurnEquip", cleanFurnEquip)
gm.reg("showFurndata", showFurndata)
gm.reg("gmReqNpcData", gmReqNpcData)
gm.reg("gmReqAddNewSpecialNpc", gmReqAddNewSpecialNpc)
gm.reg("gmFurnLogin", gmFurnLogin)

net.regMessage(ProtoDef.ReqFurnitureInfo.id, ReqFurnitureInfo, net.messType.gate)
net.regMessage(ProtoDef.ReqNpcInfo.id, ReqNpcInfo, net.messType.gate)
net.regMessage(ProtoDef.ReqNpcData.id, ReqNpcData, net.messType.gate)

net.regMessage(ProtoDef.ReqSetSellOrder.id, ReqSetSellOrder, net.messType.gate)
net.regMessage(ProtoDef.ReqShopSell.id, ReqShopSell, net.messType.gate)
net.regMessage(ProtoDef.ReqShopBuy.id, ReqShopBuy, net.messType.gate)

net.regMessage(ProtoDef.ReqShopAdvise.id, ReqShopAdvise, net.messType.gate)
net.regMessage(ProtoDef.ReqShopRefuse.id, ReqShopRefuse, net.messType.gate)
net.regMessage(ProtoDef.ReqShopPayMoreOrLess.id, ReqShopPayMoreOrLess, net.messType.gate) -- 黄色npc     卖东西给我   
net.regMessage(ProtoDef.ReqShopRiseOrDisCount.id, ReqShopRiseOrDisCount, net.messType.gate) -- 白色npc    我卖东西给npc
net.regMessage(ProtoDef.ReqShopTalk.id, ReqShopTalk, net.messType.gate)

net.regMessage(ProtoDef.ReqExtendShop.id, ReqExtendShop, net.messType.gate)
net.regMessage(ProtoDef.ReqCompleteExtendShop.id, ReqCompleteExtendShop, net.messType.gate)
net.regMessage(ProtoDef.ReqBuyFurniture.id, ReqBuyFurniture, net.messType.gate)
net.regMessage(ProtoDef.ReqUpgradeFurniture.id, ReqUpgradeFurniture, net.messType.gate)
net.regMessage(ProtoDef.ReqCompleteUpgradeFurniture.id, ReqCompleteUpgradeFurniture, net.messType.gate)
net.regMessage(ProtoDef.ReqStoreFurniture.id, ReqStoreFurniture, net.messType.gate)
net.regMessage(ProtoDef.ReqEditFurniture.id, ReqEditFurniture, net.messType.gate)
net.regMessage(ProtoDef.ReqAddGoods.id, ReqAddGoods, net.messType.gate)
net.regMessage(ProtoDef.ReqChangeFloor.id, ReqChangeFloor, net.messType.gate)
net.regMessage(ProtoDef.ReqAddNewSpecialNpc.id, ReqAddNewSpecialNpc, net.messType.gate)
net.regMessage(ProtoDef.ReqMakeEquipNpcLeave.id, ReqMakeEquipNpcLeave, net.messType.gate)
net.regMessage(ProtoDef.ReqNpcTrade.id, ReqNpcTrade, net.messType.gate)

return furnituresystem
