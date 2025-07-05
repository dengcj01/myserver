local bagsystem = {}

local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"
local util = require "common.util"
local playermoduledata = require "common.playermoduledata"

local equipAttributeCfg = require "logic.config.equipAttribute"
local itemConfig = require "logic.config.itemConfig"
local equipConfig = require "logic.config.equip"
local furnitureConfig = require "logic.config.furniture"
local heroConfig = require "logic.config.hero"
local systemConfig = require "logic.config.system"



local cacheQuilityConfig = {} -- {[品质]={[阶级]={装备id,...},...}}
local cacheStepConfig = {} -- {[阶级]=投喂值}
for k, v in pairs(equipConfig) do
    local equipQuality = v.equipQuality
    local rank = v.rank
    cacheQuilityConfig[equipQuality] = cacheQuilityConfig[equipQuality] or {}
    local qualityData = cacheQuilityConfig[equipQuality]

    qualityData[rank] = qualityData[rank] or {}

    local rankData = qualityData[rank]

    table.insert(rankData, k)

    cacheStepConfig[rank] = v.feedValue
end


-- 家具控制普通材料堆叠限的id列表
local itemFurnitureList = {120001, 120002, 120003, 120004, 120005, 120006, 120007, 120008, 120009, 120010, 120011, 120012} 

local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.bag)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.bag)
end

local function getTmpData(pid)
    return playermoduledata.getPlayerTmpData(pid, define.playerTmpDataIdDefine.bag)
end

local function getCurrencyData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.currency)
end

local function saveCurrencyData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.currency)
end

local function getItemHistoryData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.itemHistory)
end

local function saveItemHistoryData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.itemHistory)
end

local function getCacheSpaceData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.cacheSpace)
end

local function saveCacheSpaceData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.cacheSpace)
end



-- 检查配置 
function gcheckAllConfigRight()
    -- id是否重复

    -- 物品重复获得转其他东西,是否发生死循环
end

-- 根据装备品质获取对应的装备阶级数据
function bagsystem.getEquipStepByQuality(quality)
    return cacheQuilityConfig[quality]
end

-- 根据装备阶级获取投喂值
function bagsystem.getEquipStepFoodVal(step)
    return cacheStepConfig[step]
end

local function isStack(itemType)
    if itemType == define.itemType.item then
        return true
    elseif itemType == define.itemType.equip then
        return false
    end
    return true
end

function bagsystem.getCurrencyNumById(player, id)
    id = tostring(id)
    local data = getCurrencyData(player) or {}
    return data[id] or 0
end

local function checkCurrencyRange(itemList)
    local minVal = define.currencyType.none
    local maxVal = define.currencyType.max

    for k, v in pairs(itemList) do
        if k <= minVal or k > maxVal then
            return true
        end
    end

    return false
end

local function addCurrency(player, pid, datas, itemList, itemCache, tipCurRd)
    if checkCurrencyRange(itemList) then
        print("addCurrency currency overflow", pid)
        tools.ss(itemList)
        return
    end
    
    local msgs = {currency = {}}

    local currency = msgs.currency
    itemCache = itemCache or {}
    local etmax = itemCache[tostring(define.currencyType.goodWill)] or 0
    for k, v in pairs(itemList) do
        local sk = tostring(k)
        local now = datas[sk] or 0
        local cnt = now + v
        local addCnt = v
        local ok = true
        if k == define.currencyType.goodWill then
            if now >= etmax then
                ok = false
            else
                addCnt = etmax - now
                if cnt > etmax then
                    cnt = etmax
                end
            end
        end

        if ok then
            datas[sk] = cnt
            table.insert(currency, {id = k, value = cnt})
    
            tools.accRdCount(tipCurRd, k, addCnt)

            _G.gluaFuncUpdateTaskProcess(player, pid, define.taskType.achiPageCount, {v}, define.taskValType.add, {k})
        end

    end

    if next(currency) then
        saveCurrencyData(player)

        net.sendMsg2Client(player, ProtoDef.NotifyCurrencyUpdate.name, msgs)
    end

    return
end

local function costCurrency(player, datas, itemList)
    local delMsg = {
        currency = {}
    }
    local upMsg = {
        currency = {}
    }

    local dmsg = delMsg.currency
    local umsg = upMsg.currency

    for k, v in pairs(itemList) do
        local sk = tostring(k)
        local cnt = (datas[sk] or 0)

        cnt = cnt - v

        if cnt <= 0 then
            table.insert(dmsg, k)
            datas[sk] = nil
        else
            table.insert(umsg, {
                id = k,
                value = cnt
            })
            datas[sk] = cnt
        end
    end


    saveCurrencyData(player)

    if next(dmsg) then
        net.sendMsg2Client(player, ProtoDef.NotifyDeleteCurrency.name, delMsg)
    end

    if next(umsg) then
        net.sendMsg2Client(player, ProtoDef.NotifyCurrencyUpdate.name, upMsg)
    end
end

local function checkCurrency(datas, itemList)
    for k, v in pairs(itemList) do
        local sk = tostring(k)
        if (datas[sk] or 0) < v then
            return false
        end
    end

    return true
end

function bagsystem.packEquipAttr(attrs)
    local ret = {}
    for k, v in pairs(attrs or {}) do
        table.insert(ret, {type = tonumber(k), value = v})
    end

    return ret
end

local function packEuipInfo(item)
    local info = {}

    info.level = item.level or 0
    info.exp = item.exp or 0
    info.isLock = item.isLock or 0
    info.quality = item.quality or 1
    info.owner = item.owner or 0
    info.ownerType = item.ownerType or 0
    info.idx = item.idx or 0

    info.attrs = bagsystem.packEquipAttr(item.attrs)

    return info
end


function bagsystem.packOneItemInfo(uid, info)
    local msg = {}
    msg.uid = uid
    msg.item = {id = info.id, count = info.count, type = info.type}
    msg.equip = packEuipInfo(info)


    return msg
end



local function ReqAllBagInfo(player, pid, proto)
    local datas = getData(player) or {}

    local msgs = {bag = {}}

    local bag = msgs.bag
    for k, v in pairs(datas) do
        local msg = bagsystem.packOneItemInfo(k, v)
        table.insert(bag, msg)
    end
    
    net.sendMsg2Client(player, ProtoDef.ResAllBagInfo.name, msgs)
end

local function ReqCacheItemInfo(player, pid, proto)
    local datas = getCacheSpaceData(player) or {}
    local msgs = {data = {}}
    local data = msgs.data
    local curId = define.currencyType.goodWill
    for k, v in pairs(datas.normal or {}) do
        table.insert(data, {id=tonumber(k), cnt = v})
    end

    net.sendMsg2Client(player, ProtoDef.ResCacheItemInfo.name, msgs)
end

function bagsystem.notifyBagInfoSignUp(player, items, uid)
    local msgs = {
        bag = {}
    }

    local item = items[1]
    if not item then
        return
    end

    table.insert(msgs.bag, {
        uid = uid,
        item = {
            id = item.id,
            count = item.count,
            type = item.type
        },
        equip = packEuipInfo(item)
    })

    net.sendMsg2Client(player, ProtoDef.NotifyBagInfoSignUp.name, msgs)
end

local function notifyDeleteItem(player, uids)
    local msgs = {
        bag = {}
    }
    msgs.bag = uids

    net.sendMsg2Client(player, ProtoDef.NotifyDeleteItem.name, msgs)
end


function bagsystem.initEquipMainAttr(equipId, cfg)
    local mainAttr = tools.formatWeightTab(cfg.mainAttribute)

    local allWeight = mainAttr.allWeight
    if allWeight > 0 then
        local id = 0
        local val = math.random(1, allWeight)
        for k, v in ipairs(mainAttr.arr) do
            if val <= v.weight then
               id = v.id
               break 
            end
        end

        if id > 0 then
            local attrCfg = equipAttributeCfg[id]
            if attrCfg then
                if attrCfg.kind ~= define.equipHeadwordType.main then
                    print("initEquipMainAttr err", equipId, id)
                else
                    local range = attrCfg.range
                    local val1 = range[1] * 10000
                    local val2 = range[2] * 10000
                    local attrVal = math.random(val1, val2)

                    return id, attrVal
                end
            end
        end
    end
end

function bagsystem.addSubAttr(equipId, attributeCfg, filterList, filterTypeList)
    local subAttr = tools.formatWeightTab(attributeCfg, filterList, filterTypeList)
    local allWeight = subAttr.allWeight
    local arr = subAttr.arr

    local id = 0
    local val = math.random(1, allWeight)
    for k, v in ipairs(arr) do
        if val <= v.weight then
           id = v.id
           break 
        end
    end

    if id > 0 then
        local attrCfg = equipAttributeCfg[id]
        if attrCfg then
            if attrCfg.kind ~= define.equipHeadwordType.sub then
                print("initEquipSubAttr err", equipId, id)
            else
                local range = attrCfg.range
                local val1 = range[1] * 10000
                local val2 = range[2] * 10000
                local attrVal = math.random(val1, val2)

                table.insert(filterList, id)
                return id, attrVal
            end
        end
    end
end

function bagsystem.initEquipSubAttr(equipId, mainAttrId, quality, attributeCfg)
    mainAttrId = mainAttrId or 0
    local systemConf = systemConfig[0]
    local initConf = systemConf.initialAttributes
    local idxCfg = initConf[quality]
    if not idxCfg or #idxCfg < 2 then
        print("initEquipSubAttr no idxcfg", equipId)
        return {}
    end

    local cnt = math.random(idxCfg[1], idxCfg[2])

    local ret = {}
    local filterList = {mainAttrId}
    local filterTypeList = {}
    local mainAttrCfg = equipAttributeCfg[mainAttrId]
    if mainAttrCfg then
        table.insert(filterTypeList, mainAttrCfg.type)
    end

    for i=1, cnt do
        local id, value = bagsystem.addSubAttr(equipId, attributeCfg, filterList, filterTypeList)
        if id ~= nil then
            table.insert(ret, {type=id, value = value})
        end
    end
    
    return ret
end

local function initItem(player,pid, uid, itemId, count, itemType, subType)
    local item = {
        id = itemId,
        count = count,
        type = itemType,
        subTyep = subType,
    }

    if itemType == define.itemType.equip then
        local config = equipConfig[itemId]
        if not config then
            print("initItem err no this id", pid, itemId, itemType)
        else
            item.attrs = {}
            local attrs = item.attrs
            local quality = config.equipQuality
            item.quality = quality

            local id, val = bagsystem.initEquipMainAttr(itemId, config)
            if id ~= nil then
                item.mainId = id
                attrs[tostring(id)] = val

                local ret = bagsystem.initEquipSubAttr(itemId, id, quality, config.Attribute)

                item.subCnt = #ret -- 副词条数量
                for k, v in pairs(ret) do
                    attrs[tostring(v.type)] = v.value
                end
            end
        end

    end

    return item
end

local function getHasEquipNumber(player)
    local data = getData(player)
    local cnt = 0
    for k, v in pairs(data) do
        if v.type == define.itemType.equip then
            cnt = cnt + 1
        end
    end

    return cnt
end




-- 道具上限转其他
local function addItem(player, pid, tipItemRd, equipRd, id2Item, itemData, msgs, itemId, count, itemType, cacheSpaceData, historyData, extra)
    local sid = tostring(itemId)
    local list = id2Item[itemId]

    local isItem = isStack(itemType)


    if list == nil then
        if isItem then
            local cfg = itemConfig[itemId]

            local type = cfg.type

            if cfg.fun_shardNum > 0 and #cfg.regain == 3 then
                historyData[sid] = (historyData[sid] or 0) + count
            end

            local uid = gTools:createUniqueId()
            local suid = tostring(uid)
            local item = initItem(player,pid, uid, itemId, count, itemType, type)

            itemData[suid] = item

            id2Item[itemId] = {}
            list = id2Item[itemId]
            
            table.insert(list, suid)
            table.insert(msgs, {uid = suid,item = {id = itemId, count = count, type = itemType}})
            tools.accRdCount(tipItemRd, itemId, count)
        else
            local ok = false
            local equipSpace = cacheSpaceData.equipSpace or 0
            if equipSpace <= 0 then
                print("addItem no equipSpace", pid, itemId, count, equipSpace)
                return false
            end

            count = tools.getMinVal(count, equipSpace)

            tools.accRdCount(equipRd, itemId, count)
            for i = 1, count do
                local uid = gTools:createUniqueId()
                local suid = tostring(uid)
                local item = initItem(player,pid, uid, itemId, count, itemType)

                itemData[suid] = item

                if ok == false then
                    id2Item[itemId] = {}
                    list = id2Item[itemId]

                    table.insert(list, suid);

                    ok = true
                else
                    table.insert(list, suid);
                end

                table.insert(msgs, {uid = suid, item = { id = itemId, count = count, type = itemType}, equip = packEuipInfo(item)});
                
            end

            cacheSpaceData.equipSpace = equipSpace - count

        end   
    else
        if isItem then
            local suid = list[1]
            if suid then
                local item = itemData[suid]
                local cfg = itemConfig[itemId]
                if item then
                    local oldCount = item.count or 0
                    if cfg.fun_shardNum > 0 and #cfg.regain == 3 then
                        historyData[sid] = (historyData[sid] or 0) + count
                    end

                    local totalCnt = oldCount + count

                    item.count = totalCnt

                    table.insert(msgs, {uid = suid, item = {id = itemId, count = totalCnt, type = itemType}})

                    tools.accRdCount(tipItemRd, itemId, count)
                else
                    print("addItem err1 no find item", pid, itemId, count, itemType, suid)
                end
            else
                print("addItem err2 no find uid", pid, itemId, count, itemType)
            end
        else
            local equipSpace = cacheSpaceData.equipSpace or 0
            if equipSpace <= 0 then
                print("addItem no equipSpace", pid, itemId, count, equipSpace)
                return false
            end
            
            count = tools.getMinVal(count, equipSpace)

            tools.accRdCount(equipRd, itemId, count)

            local oldCount = #list
            for i = 1, count do
                local uid = gTools:createUniqueId()
                local suid = tostring(uid)
                local item = initItem(player,pid, uid, itemId, count, itemType)

                itemData[suid] = item
                table.insert(list, suid)

                table.insert(msgs, {
                    uid = suid,
                    item = {
                        id = itemId,
                        count = count,
                        type = itemType
                    },
                    equip = packEuipInfo(item)
                })
            end

            cacheSpaceData.equipSpace = equipSpace - count
        end
    end


end

function bagsystem.makeNotice(p1, p2, p3, p4, p5, p6)
    local info = {}
    info.param1 = p1 or 0
    info.param2 = p2 or 0
    info.param3 = p3 or 0
    info.param4 = p4 or 0
    info.param5 = p5 or 0
    info.param6 = p6 or 0


    return info
end

local function checkArgs(player, itemList, extra)
    if type(player) ~= "userdata" then
        return false
    end

    extra = extra or {}
    local collect = extra.collect
    if collect then
        return true
    end

    if next(itemList) == nil or type(itemList) ~= "table" or not tools.isArr(itemList) then
        return false
    end

    return true
end

function bagsystem.enterCacheSpace(player, pid, itemList, enterCache)
    local cacheSpaceData = getCacheSpaceData(player) or {}
    local leftSpace = cacheSpaceData.leftSpace or 0

    local itemType = define.itemType.item
    itemList = tools.megerReward(itemList)
    cacheSpaceData.normal = cacheSpaceData.normal or {}
    local normal = cacheSpaceData.normal


    local list = itemList[itemType]
    for k, v in pairs(list or {}) do

        local sid = tostring(k)
        v = tools.getMinVal(v, leftSpace)
        if v > 0 then
            normal[sid] = (normal[sid] or 0) + v
            leftSpace = leftSpace - v
    
            enterCache[k] = v
        end
    end

    cacheSpaceData.leftSpace = leftSpace
    saveCacheSpaceData(player)
end

function bagsystem.moveItem(player, pid, extra)
    local cacheSpaceData = getCacheSpaceData(player)

    local itemType = define.itemType.item
    local itemCache = cacheSpaceData.itemCache or {}
    local leftSpace = cacheSpaceData.leftSpace or 0
    local rareLeftSpace = cacheSpaceData.rareLeftSpace or 0
    cacheSpaceData.normal = cacheSpaceData.normal or {}
    local normal = cacheSpaceData.normal

    local list = {}
    local leaveCache = extra.leaveCache

    for k, v in pairs(normal) do
        local itemId = tonumber(k)
        local cfg = itemConfig[itemId]
        local now = bagsystem.getItemCountByIdAndType(player, pid, itemId, itemType)

        if cfg.type == define.itemSubType.normalMaterial then
            local maxStack = itemCache[k] or 0
            if maxStack > 0 and v > 0 then
                local left = maxStack - now 
                if left > 0 then
                    local count = tools.getMinVal(v, left)
                    table.insert(list, {id=itemId,count=count,type=itemType})
                    leftSpace = leftSpace + count
    
    
                    leaveCache[itemId] = count
                    normal[k] = v - count
                end
            end
        else
            if rareLeftSpace > 0 and v > 0 then 
                local left = rareLeftSpace - now 
                if left > 0 then
                    local count = tools.getMinVal(v, left)
                    table.insert(list, {id=itemId,count=count,type=itemType})
                    leftSpace = leftSpace + count
    
                    leaveCache[itemId] = count
                    normal[k] = v - count
                end
            end
        end 

    end

    cacheSpaceData.leftSpace = leftSpace
    saveCacheSpaceData(player)

    if next(list) == nil then
        local msgs = {rdType = define.rewardTypeDefine.collect}
        local showRd = {}
        for k, v in pairs(extra.enterCache or {}) do
            table.insert(showRd, {id=k, count=v, type=itemType, opt = 1})
        end

        msgs.data = showRd
        net.sendMsg2Client(player, ProtoDef.NotifyClientRewardTips.name, msgs)
    else
        bagsystem.addItems(player, list, define.rewardTypeDefine.collect, nil, extra)
    end

    
end

-- 奖励格式 itemList = {{id=1,count=2,type=4},...}
function bagsystem.addItems(player, itemList, rdType, notice, extra)
    extra = extra or {}
    extra.formaluaMsg = {}
    
    local pid = player:getPid()
    if not checkArgs(player, itemList, extra) then
        print("--------------------addItem err empty itemlist", pid)
        printTrace()
        return
    end

    local currencyData = getCurrencyData(player)
    if not currencyData then
        print("addItems no datas", pid)
        return
    end

    local tmpData = getTmpData(pid)
    if not tmpData then
        print("addItems no tmpData", pid)
        return
    end

    local bagData = getData(player)
    if not bagData then
        print("addItems no bagData", pid)
        return
    end

    local cacheSpaceData = getCacheSpaceData(player)
    if not cacheSpaceData then
        print("addItems no cacheSpaceData", pid)
        return
    end

    local historyData = getItemHistoryData(player)
    if not historyData then
        print("addItems no historyData", pid)
        return
    end

    itemList = tools.megerReward(itemList)
    -- 未处理,检出策划配置物品类型出错, 开服检出重复id

    local heroType = define.itemType.hero
    local furnitureType = define.itemType.furniture
    local equipType = define.itemType.equip
    local itemType = define.itemType.item
    local currencyType = define.itemType.currency


    for k, v in pairs(itemList) do
        for id, count in pairs(v) do
            if count <= 0 then
                print("addItems count is zero", pid, k, id)
                return
            end

            if k == equipType and equipConfig[id] == nil then
                print("addItems equipConfig no find this id", pid, id)
                return
            end

            if k == furnitureType and furnitureConfig[id] == nil then
                print("addItems furnitureConfig no find this id", pid, id)
                return
            end

            if k == heroType and heroConfig[id] == nil then
                print("addItems heroConfig no find this id", pid, id)
                return
            end
        end
    end

    local tipItemRd = {} -- 物品

    itemList[itemType] = itemList[itemType] or {}
    itemList[furnitureType] = itemList[furnitureType] or {}
    itemList[equipType] = itemList[equipType] or {}
    itemList[heroType] = itemList[heroType] or {}
    itemList[currencyType] = itemList[currencyType] or {}

    local itemRd = itemList[itemType]
    local currencyRd = itemList[currencyType]
    _G.gluaFuncChangeHeroItem(player, itemList[heroType], itemRd)
    _G.gluaFuncChangeFurnitureItem(player, itemList[furnitureType], itemRd, currencyRd)
    _G.gluaFuncAutoUseFormula(player, pid, itemRd, tipItemRd, extra)

    local changeRd = {}
    for id, count in pairs(itemRd) do
        if count <= 0 then
            print("addItems count is zero", pid, itemType, id)
            return
        end

        local cfg = itemConfig[id]
        if cfg == nil then
            print("addItems itemConfig no find this id", pid, id)
            return
        end

        local regain = cfg.regain or {}
        local cnt = #regain
        local funShardNum = cfg.fun_shardNum
        if funShardNum > 0 and cnt == 3 then
            local changeType = regain[1]
            local changeId = regain[2]
            if changeType == itemType then
                local cfg1 = itemConfig[changeId]
                if cfg1 == nil then
                    print("addItems itemConfig1 no find this id", pid, changeId)
                    return
                end
            end

            local sid = tostring(id)
            historyData[sid] = historyData[sid] or 0
            local hisCnt = historyData[sid]
            local changeCnt = nil
            if hisCnt >= funShardNum then
                changeCnt = count
                itemRd[id] = nil
            else
                local left = funShardNum - hisCnt
                if count > left then
                    changeCnt = count - left
                    itemRd[id] = left
                end
            end

            if changeCnt then
                changeRd[1] = changeType
                changeRd[2] = changeId
                changeRd[3] = regain[3] * changeCnt
            end
        end
    end

    if next(changeRd) then
        local typeData = itemList[changeRd[1]]
        local id = changeRd[2]
        typeData[id] = (typeData[id] or 0) + changeRd[3]
    end





    local tipCurRd = {} -- 货币
    local equipRd = {} -- 装备
    local furnRd = {} -- 家具
    local heroRd = {} -- 英雄

    local currency = itemList[currencyType] or {}
    local heros = itemList[heroType] or {}
    local furniture = itemList[furnitureType] or {}



    -- 处理家具
    if next(furniture) then
        _G.gluaFuncAddFurnitures(player, pid, furniture, cacheSpaceData, furnRd, extra)
    end

    -- 处理货币
    if next(currency) then
        addCurrency(player, pid, currencyData, currency, cacheSpaceData.itemCache, tipCurRd)
    end

    -- 处理英雄
    if next(heros) then
        _G.gluaFuncAddHeros(player, pid, heros, heroRd, extra)
    end


    itemList[currencyType] = nil
    itemList[heroType] = nil
    itemList[furnitureType] = nil

    local equipFlag = nil
    -- 这里的东西进背包  物品,装备
    if next(itemList) then
        local msgs = {bag = {}}

        for itemType, v in pairs(itemList) do
            for id, cnt in pairs(v) do
                local ok = addItem(player, pid, tipItemRd, equipRd, tmpData, bagData, msgs.bag, id, cnt, itemType, cacheSpaceData, historyData, extra)

                if ok == false and equipFlag == nil then
                    equipFlag = true
                end
            end
        end

        if next(msgs.bag) then
            net.sendMsg2Client(player, ProtoDef.NotifyBagInfoSignUp.name, msgs)
        end
    end

    saveData(player)
    saveItemHistoryData(player)
    saveCacheSpaceData(player)

    local showRd = {}
    for k, v in pairs(tipItemRd) do
        table.insert(showRd, {id=k, count=v, type=itemType})
    end
    for k, v in pairs(tipCurRd) do
        table.insert(showRd, {id=k, count=v, type=currencyType})
    end
    for k, v in pairs(equipRd) do
        table.insert(showRd, {id=k, count=v, type=equipType})
    end
    for k, v in pairs(furnRd) do
        table.insert(showRd, {id=k, count=v, type=furnitureType})
    end
    for k, v in pairs(heroRd) do
        table.insert(showRd, {id=k, count=v, type=heroType})
    end

    if notice == nil then
        notice = bagsystem.makeNotice()
    end

    if rdType == nil then
        rdType = define.rewardTypeDefine.show
    end

    if notice.nsend == nil then
        local tipMsg = {}
        tipMsg.param1 = notice.param1
        tipMsg.param2 = notice.param2
        tipMsg.param3 = notice.param3
        tipMsg.param4 = notice.param4
        tipMsg.param5 = notice.param5
        tipMsg.param6 = notice.param6
        tipMsg.rdType = rdType

        for k, v in pairs(extra.enterCache or {}) do
            table.insert(showRd, {id=k, count=v, type=itemType, opt = 1})
        end

        for k, v in pairs(extra.leaveCache or {}) do
            table.insert(showRd, {id=k, count=v, type=itemType, opt = 2})
        end

        tipMsg.data = showRd
    
        if next(showRd) then
            net.sendMsg2Client(player, ProtoDef.NotifyClientRewardTips.name, tipMsg)
        end
        
    end

    if extra.formaluaMsg then
        for _, msg in ipairs(extra.formaluaMsg or {}) do
            net.sendMsg2Client(player, ProtoDef.NotifyUpFormulaInfo.name, msg)
        end

    end

    return equipFlag
end

local function costItem(player, pid, datas, tmpData, delMsg, upMsg, idxList, id, count, type, cacheSpaceData, extra)
    local list = tmpData[id] or {}
    local len = #list
    local subCnt = 0

    local normal = cacheSpaceData.normal
    local cnt = cacheSpaceData.equipSpace or 0

    local cfg = itemConfig[id]
    if not cfg then
        cfg = equipConfig[id]
        if not cfg then
            return
        end
    end

    local clear = extra.clear

    local sid = tostring(id)

    local heroType = define.itemType.hero
    local carriageType = define.itemType.carriage
    local furnList = {}
    local runCnt = 0


    for i = len, 1, -1 do
        local suid = list[i]

        local item = datas[suid]

        if item then
            local uid = tonumber(suid)
            if isStack(item.type) then
                item.count = item.count - count

                if item.count <= 0 then
                    table.insert(delMsg, uid)
                    tmpData[id] = nil
                else
                    table.insert(upMsg, {
                        uid = uid,
                        item = {
                            id = id,
                            count = item.count,
                            type = type
                        }
                    })
                end


            else
                local owner = item.owner
                local ownerType = item.ownerType
                local delFlag = true
                if owner and (ownerType == heroType or ownerType == carriageType) then
                    delFlag = false
                end

                if delFlag then

                    if subCnt >= count then
                        break
                    end

                    runCnt = runCnt + 1
    
                    table.insert(delMsg, uid)

                    if owner then
                        furnList[owner] = furnList[owner] or {}
                        local flist = furnList[owner]
                        table.insert(flist, suid)
                    end
                    
                    subCnt = subCnt + 1
    
                    idxList[id] = idxList[id] or {} -- 不可堆叠的要删除的映
                    local list1 = idxList[id]
    
                    table.insert(list1, i)
                    cnt = cnt + 1
                end

            end
        end
    end

    _G.gluaFuncDeleteFurnEquip(player, furnList)

    for k, v in pairs(delMsg) do
        local suid = tostring(v)
        datas[suid] = nil
    end

    for k, v in pairs(idxList) do
        local list = tmpData[k] or {}

        for _, idx in ipairs(v) do
            table.remove(list, idx)
        end

        if next(list) == nil then
            tmpData[k] = nil
        end
    end

    if runCnt ~= count and extra.check then
        extra.res = 1
    end


    cacheSpaceData.equipSpace = cnt

end

-- 和 bagsystem.checkItemEnough 配对使用,禁止直接使用
function bagsystem.costItems(player, itemList, extra)
    local pid = player:getPid()
    local currencyData = getCurrencyData(player)
    if not currencyData then
        print("costItems no datas", pid)
        return false
    end

    local tmpData = getTmpData(pid)
    if not tmpData then
        print("costItems no tmpData", pid)
        return false
    end

    local bagData = getData(player)
    if not bagData then
        print("costItems no bagData", pid)
        return false
    end

    local cacheSpaceData = getCacheSpaceData(player)
    if not cacheSpaceData then
        print("costItems no cacheSpaceData", pid)
        return false
    end

    itemList = tools.megerReward(itemList)

    local currenType = define.itemType.currency
    local currency = itemList[currenType] or {}

    if next(currency) then
        costCurrency(player, currencyData, currency)
    end

    itemList[currenType] = nil

    extra = extra or {}

    if next(itemList) then
        local delMsg = {}
        local upMsg = {
            bag = {}
        }
        local bag = upMsg.bag
        local idxList = {}


        for type, v in pairs(itemList) do
            for id, cnt in pairs(v) do
                costItem(player, pid, bagData, tmpData, delMsg, bag, idxList, id, cnt, type, cacheSpaceData, extra)
            end
        end

        if next(delMsg) then
            -- net.sendMsg2Client(player, ProtoDef.NotifyDeleteItem.name, delMsg)
            -- print("222222222222222222222222222")
            notifyDeleteItem(player, delMsg)
        end

        if next(bag) then
            -- print("11111111111111111111111111111111111111111")
            -- tools.ss(upMsg)
            net.sendMsg2Client(player, ProtoDef.NotifyBagInfoSignUp.name, upMsg)
        end

        saveData(player)
        saveCacheSpaceData(player)
    end

    return true
end


local function checkItem(player, pid, datas, id, count, type, tmpData, itemCache)
    local list = tmpData[id] or {}
    local len = #list
    if len <= 0 then
        print("checkItem list is zero", pid, id, count)
        return false
    end

    local cfg = itemConfig[id]
    if not cfg then
        print("checkItem no confg", pid, id)
        return false
    end


    local sid = tostring(id)
    local subType = cfg.type
    if isStack(type) then
        local suid = list[1]
        local item = datas[suid] or {}
        local now = item.count or 0

        if now < count then
            return false
        end
    else
        return len >= count
    end

    return true
end
 
-- 仅检查物品是否足够
function bagsystem.checkItemEnough(player, itemList)
    local pid = player:getPid()
    if not checkArgs(player, itemList) then
        print("checkItemEnough err", pid)
        tools.ss(itemList)
        return false
    end

    local currencyData = getCurrencyData(player)
    if not currencyData then
        print("checkItemEnough no datas", pid)
        return false
    end

    local tmpData = getTmpData(pid)
    if not tmpData then
        print("checkItemEnough no tmpData", pid)
        return false
    end

    local bagData = getData(player)
    if not bagData then
        print("checkItemEnough no bagData", pid)
        return false
    end

    local cacheSpaceData = getCacheSpaceData(player)
    if not cacheSpaceData then
        print("checkItemEnough no cacheSpaceData", pid)
        return false
    end

    itemList = tools.megerReward(itemList)
    if itemList[define.itemType.hero] or itemList[define.itemType.furniture] then
        print("checkItemEnough cost item have no cost type", pid)
        tools.ss(itemList)
        return false
    end

    local currencyType = define.itemType.currency
    local currency = itemList[currencyType] or {}

    if next(currency) and not checkCurrency(currencyData, currency) then
        print("checkItemEnough currency no enough", pid)
        tools.ss(itemList)
        return false
    end

    itemList[currencyType] = nil

    if next(itemList) then
        for type, v in pairs(itemList) do
            for id, cnt in pairs(v) do
                if not checkItem(player, pid, bagData, id, cnt, type, tmpData, cacheSpaceData.itemCache) then
                    print("checkItemEnough item no enough..........", pid, id, cnt)
                    return false
                end
            end
        end
    end

    return true
end

-- 先检查成功,在删除背包物品,失败不处理
function bagsystem.checkAndCostItem(player, itemList)
    if not bagsystem.checkItemEnough(player, itemList) then
        return false
    end

    if not bagsystem.costItems(player, itemList) then
        print("checkAndCostItem costItems not enougt ")
        return false
    end

    return true

end

-- 初始化物品查找索引
local function InitItemIndex(pid, data)
    local tmpData = getTmpData(pid)
    for k, v in pairs(data or {}) do
        if v.id and v.type then
            local itemId = v.id
            local itemType = v.type
            local list = tmpData[itemId]

            if list == nil then
                tmpData[itemId] = {}
                list = tmpData[itemId]
                table.insert(list, k)
            else
                if not isStack(itemType) then
                    table.insert(list, k)
                end
            end
        end
        
    end
end

-- 获取物品信息,根据物品唯一id
function bagsystem.getItemInfo(player, pid, uid)
    local datas = getData(player)
    if not datas then
        print("getItemInfo no datas", pid)
        return
    end

    return datas[tostring(uid)]
end

-- 根据物品guid, 获得该物品数量
function bagsystem.getItemCountByGuid(player, pid, guid, isSame)
    if isSame == nil then
        isSame = true
    end

    local datas = getData(player)
    if not datas then
        print("getItemCountByGuid no datas", pid, guid)
        return 0
    end

    guid = tostring(guid)

    local data = datas[guid]
    if not data then
        return 0
    end

    local tmpData = getTmpData(pid)
    if not tmpData then
        print("getItemCountByGuid no tmpData", pid, guid)
        return 0
    end

    local ret = tmpData[data.id] or {}
    local count = #ret
    if count == 0 then
        return 0
    end

    if isStack(data.type) then
        return data.count
    end

    -- 是否返回同id的数量
    if isSame then
        return count
    else
        return data.count
    end
end

-- 根据物品对象, 获得该物品数量
function bagsystem.getItemCountByItem(player, pid, data, isSame)
    if isSame == nil then
        isSame = true
    end

    local tmpData = getTmpData(pid)
    if not tmpData then
        print("getItemCountByGuid no tmpData", pid)
        return 0
    end

    local ret = tmpData[data.id] or {}
    local count = #ret
    if count == 0 then
        return 0
    end

    if isStack(data.type) then
        return data.count
    end

    -- 是否返回同id的数量
    if isSame then
        return count
    else
        return data.count
    end
end

-- 根据物品id,类型, 获得该物品数量
function bagsystem.getItemCountByIdAndType(player, pid, id, type)
    local datas = getData(player)
    if not datas then
        print("getItemCountByIdAndType no datas", pid, id)
        return 0
    end

    local tmpData = getTmpData(pid)
    if not tmpData then
        print("getItemCountByIdAndType no tmpData", pid, id)
        return 0
    end

    local ret = tmpData[id] or {}
    local count = #ret
    if count == 0 then
        return 0
    end

    if isStack(type) then
        local guid = ret[1]
        local item = datas[guid] or {}
        return item.count or 0
    end

    return count

end

-- 根据物品唯一id删除装备
-- delList = {[装备id]={guid,guid},[装备id]={guid,guid}}
function bagsystem.deleteEquipByUid(player, pid, delList, isFurn)
    local datas = getData(player) or {}
    local tmpData = getTmpData(pid) or {}
    local msgs = {bag = {}}
    local del = msgs.bag
    local cacheSpaceData = getCacheSpaceData(player)
    local cnt = cacheSpaceData.equipSpace
    local furnList = {}

    isFurn = isFurn or false
    local frunType = define.itemType.furniture

    for k, v in pairs(delList) do
        local list = tmpData[k] or {}
        for _, uid in pairs(v) do
            local sid = tostring(uid)
            local idx = tools.getItemIndex(list, sid)
            local mdata = datas[sid]
            if idx > 0 and mdata then
                
                local owner = mdata.owner
                if isFurn or (owner and mdata.ownerType == frunType) then
                    furnList[owner] = furnList[owner] or {}
                    local flist = furnList[owner]
                    table.insert(flist, sid)
                end


                table.remove(list, idx)
                datas[sid] = nil
                table.insert(del, uid)
                cnt = cnt + 1
            end
        end
    end

    cacheSpaceData.equipSpace = cnt
    saveCacheSpaceData(player)

    if next(delList) then
        net.sendMsg2Client(player, ProtoDef.NotifyDeleteItem.name, msgs)

    end

    _G.gluaFuncDeleteFurnEquip(player, furnList)
    
end




local function ReqCurrencyInfo(player, pid, proto)
    local datas = getCurrencyData(player) or {}

    local msgs = {currency = {}}
    local currency = msgs.currency
    for k, v in pairs(datas) do
        table.insert(currency, {
            id = tonumber(k),
            value = v
        })
    end

    net.sendMsg2Client(player, ProtoDef.ResCurrencyInfo.name, msgs)
end

local function ReqBagItemLock(player, pid, proto)
    local  uid, isLock =  proto.uid, proto.isLock

    local data = getData(player)
    local euqip = data[uid]
    if not euqip then
        print("not find bag data uid,", pid, uid)
        return
    end

    if euqip.type ~= define.itemType.equip then
        print("not find bag data uid,", pid, uid)
        return
    end

    euqip.isLock = isLock
    
    saveData(player)

    local msgs = {}
    msgs.uid = uid
    msgs.isLock = isLock

    net.sendMsg2Client(player, ProtoDef.ResBagItemLock.name, msgs)
end

-- 更新装备等级数据
function bagsystem.updateEqupLvData(player, addList, subList)
    local datas = playermoduledata.getData(player, define.playerModuleDefine.hero)
    if not datas then
        return {}
    end

    datas.equipLvData = datas.equipLvData or {}
    local equipLvData = datas.equipLvData

    for k, v in pairs(addList or {}) do
        local slv = tostring(v)
        equipLvData[slv] = (equipLvData[slv] or 0) + 1
    end

    for k, v in pairs(subList or {}) do
        local splv = tostring(v)
        local data = equipLvData[splv]
        if data then
            equipLvData[splv] = data - 1
            if data == 0 then
                equipLvData[splv] = nil
            end
        end
    end

    playermoduledata.saveData(player, define.playerModuleDefine.hero)

    return equipLvData
end

local function ReqBagDelItem(player, pid, proto)
    local uid = proto.uid
    local data = getData(player)
    local equip = data[tostring(uid)]
    if not equip then
        print("ReqBagDelItem no equip,", pid, uid)
        return
    end

    local owner = equip.owner
    local ownerType = equip.ownerType
    if owner and (ownerType == define.itemType.hero or ownerType == define.itemType.carriage) then
        print("ReqBagDelItem have master", pid, uid)
        return
    end 

    if equip.isLock == 1 then
        print("ReqBagDelItem locked,", pid, uid)
        return
    end

    local lv = equip.level or 0
    if lv > 0 then
        bagsystem.updateEqupLvData(player, nil, {lv})
    end

    local dels = {[equip.id] = {uid}}
    bagsystem.deleteEquipByUid(player, pid, dels)

end

local function ReqUseItem(player, pid, proto)

    local id = proto.id
    local cnt = proto.cnt

    local itemCfg = itemConfig[id]
    if not itemCfg then
        print("ReqUseItem no itemCfg", pid)
        return
    end

    if itemCfg.type == define.itemSubType.studyActive then
        _G.gluaFuncAddStudyId(player, pid, id, cnt)
    end

end


local function addInitItems(player)
    local cfg = systemConfig[0]
    local heroType = define.itemType.hero
    local curencyType = define.itemType.currency
    local furnitureType = define.itemType.furniture
    local itemType = define.itemType.item
    local maxCurrenId = define.currencyType.max
    local addList = {}
    for k, v in pairs(cfg.heroInitial or {}) do
        table.insert(addList, {
            id = v,
            type = heroType,
            count = 1
        })
    end

    local extra = {}
    for k, v in pairs(cfg.furnitureInitial or {}) do
        table.insert(addList, {
            id = v[1],
            count = 1,
            type = furnitureType
        })
        extra[v[1]] = {v[2], v[3],v[4],v[5]}
    end
    

    for k, v in pairs(cfg.InitialItem or {}) do
        local type = curencyType
        if v[1] > maxCurrenId then
            type = itemType
        end

        table.insert(addList, {
            id = v[1],
            count = v[2],
            type = type
        })
    end

    local cacheSpaceData = getCacheSpaceData(player)
    cacheSpaceData.leftSpace = systemConfig[0].houseNumb
    local goodWillId = tostring(define.currencyType.goodWill) 
    cacheSpaceData.itemCache = cacheSpaceData.itemCache or {}
    local itemCache = cacheSpaceData.itemCache
    itemCache[goodWillId] = systemConfig[0].defaultEnergyLimit
    saveCacheSpaceData(player)

    if next(addList) then
        bagsystem.addItems(player, addList, define.rewardTypeDefine.notshow, nil, {
            furnitrurePos = extra,
            initFurnitrure = true
        })

    end
end

local function houtaiCostItem(data)
    local list = data.role_id or {}
    local pid = list[1]
    if not pid then
        return
    end

    local ext = data.ext
    if not ext then
        return
    end

    local num = ext.num
    if not num then
        return
    end

    pid = tonumber(pid)
    local player = gPlayerMgr:getPlayerById(pid)
    if not player then
        return
    end

    local id = ext.goods_id
    local ret = tools.splitByNumber(id, "-")
    if #ret <= 1 then
        print("houtaiCostItem err", pid, id)
        return
    end

    local cost = {{id=ret[1],type=ret[2],count=num}}
    bagsystem.checkAndCostItem(player, cost)
end

-- 装备的种类(武器,防具,饰品)
function bagsystem.getEquipKind(portion)
    for k, v in pairs(systemConfig[0].equipClassify) do
        if tools.isInArr(v, portion) then
            return k
        end
    end

    return 0
end

-- 装备的穿戴位置
function bagsystem.getEquipPos(portion)
    for k, v in pairs(systemConfig[0].equipType) do
        if tools.isInArr(v, portion) then
            return k
        end
    end

    return 0
end

function bagsystem.getGoodWillMaxVal(player)
    local cacheSpaceData = getCacheSpaceData(player)
    local goodWillId = tostring(define.currencyType.goodWill) 
    local itemCache = cacheSpaceData.itemCache
    return itemCache[goodWillId] or 0
end

local function login(player, pid, curTime, isfirst)
    if isfirst then
        addInitItems(player)
    end
end


local function additem(player, pid, args)
    local type = args[3]
    if not type then
        return
    end
    bagsystem.addItems(player, {{id = args[1],count = args[2],type = type}})
end

local function subitem(player, pid, args)
    local item = {{id=args[1], count=args[2],type= args[3] or define.itemType.item}}

    bagsystem.checkAndCostItem(player, item)
end


local function clearbag(player, pid, args)
    local equipList = {}
    local itemList = {}
    local data1 = getData(player)
    local data2 = getCurrencyData(player)
    tools.cleanTableData(data2)
    for k, v in pairs(data1) do
        if v.type == define.itemType.equip then
            if not v.owner or v.owner == 0 then
                equipList[v.id] = equipList[v.id] or {}
                local list = equipList[v.id]
                table.insert(list, k)
            end
        else
            table.insert(itemList, {id=v.id,type=define.itemType.item,count=v.count})
        end
    end

    bagsystem.deleteEquipByUid(player, pid, equipList)
    bagsystem.costItems(player, itemList, {clear=1})
    saveData(player)
    saveCurrencyData(player)
end


local function additem1(player, pid, args)
    pid = 1234
    player = gPlayerMgr:getPlayerById(pid)
    local arg1 = {}
    for k, v in ipairs(args) do
        args[k] = tonumber(v)
    end
    additem(player, pid, arg1)
end


local function clearbag1(player, pid, args)
    player = gPlayerMgr:getPlayerById(3518438940388501242)
    clearbag(player, 283205250988924, args)
end

local function showtmpdata(player, pid, args)
    player = gPlayerMgr:getPlayerById(3518438940388501242)
    bagsystem.checkAndCostItem(player, {{id=1,type=3,count=1}})
end

local function showcachespace(player, pid, args)
    player = gPlayerMgr:getPlayerById(3518438940558369355)
    tools.ss(getCacheSpaceData(player))
end

local function cleancachedata(player, pid, args)
    player = gPlayerMgr:getPlayerById(3518438940388501242)
    local datas = getCacheSpaceData(player)
    datas.itemCache = {["4"]=25}
    datas.leftSpace = 1000
    saveCacheSpaceData(player)
end

local function getitemcount(player, pid, args)
    pid = 72100907737896
    player = gPlayerMgr:getPlayerById(72100907737896)
    local xx = bagsystem.getItemCountByIdAndType(player, pid, 2016, 1)
    print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", xx)
end

local function testcostitem(player, pid, args)
    pid = 3518438940388501242
    player = gPlayerMgr:getPlayerById(3518438940388501242)
    local xx = bagsystem.getItemCountByIdAndType(player, pid, 2004, 1)
    print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", xx)
end

local function gmShowItemHistoryData(player, pid, args)
    pid = 72103082085748
    player = gPlayerMgr:getPlayerById(pid)
    local data = getItemHistoryData(player)
    tools.ss(data)
end

local function gmFixedAddRecuirt(player, pid, args)
    pid = 72103082085748
    player = gPlayerMgr:getPlayerById(pid)

    print("222222222222222222222222222")
    bagsystem.addItems(player, {{id=2,count=1,type=define.itemType.hero}})

    
end

local function gmAddAllEquip(player, pid, args) -- gmAddAllEquip 72106445424728 20
    pid = args[1]
    local cnt = args[2] or 20
    player = gPlayerMgr:getPlayerById(pid)

    -- local extra = {
    --     check = 1
    -- }
    local list = {}
    local i = 0
    for k, v in pairs(equipConfig) do
        table.insert(list,{id=k,count=1,type=define.itemType.equip})
        i = i+1
        if i >= cnt then
            break
        end
    end
    bagsystem.addItems(player, list)

end

local function gmAddAllItem(player, pid, args) -- gmAddAllItem 72106445424728
    pid = args[1]
    player = gPlayerMgr:getPlayerById(pid)

    local list = {}
    for k, v in pairs(itemConfig) do
        table.insert(list,{id=k,count=1,type=define.itemType.item})
    end
    bagsystem.addItems(player, list)
    
end

_G.gluaFuncInitItemIndex = InitItemIndex


gm.reg("additem", additem)
gm.reg("subitem", subitem)
gm.reg("clearbag", clearbag)
gm.reg("clearbag1", clearbag1)
gm.reg("additem1", additem1)
gm.reg("showtmpdata", showtmpdata)
gm.reg("showcachespace", showcachespace)
gm.reg("cleancachedata", cleancachedata)
gm.reg("getitemcount", getitemcount)
gm.reg("testcostitem", testcostitem)
gm.reg("gmShowItemHistoryData", gmShowItemHistoryData)
gm.reg("gmFixedAddRecuirt", gmFixedAddRecuirt)
gm.reg("gmAddAllEquip", gmAddAllEquip)
gm.reg("gmAddAllItem", gmAddAllItem)

event.reg(event.eventType.login, login)

event.regHttp(event.optType.player, event.httpEvent[event.optType.player].costItem, houtaiCostItem)

net.regMessage(ProtoDef.ReqAllBagInfo.id, ReqAllBagInfo, net.messType.gate)
net.regMessage(ProtoDef.ReqCurrencyInfo.id, ReqCurrencyInfo, net.messType.gate)
net.regMessage(ProtoDef.ReqBagItemLock.id, ReqBagItemLock, net.messType.gate)
net.regMessage(ProtoDef.ReqBagDelItem.id, ReqBagDelItem, net.messType.gate)
net.regMessage(ProtoDef.ReqUseItem.id, ReqUseItem, net.messType.gate)
net.regMessage(ProtoDef.ReqCacheItemInfo.id, ReqCacheItemInfo, net.messType.gate)

return bagsystem



