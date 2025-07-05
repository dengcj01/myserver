local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"
local util = require "common.util"
local playermoduledata = require "common.playermoduledata"
local furnitureConfig = require "logic.config.furniture"
local orderCustomerEquipConfig = require "logic.config.order_CustomerEquip"
local orderHeroEquipConfig = require "logic.config.order_HeroEquip"
local orderPrincessConfig = require "logic.config.order_Princess"
local constConfig = require "logic.config.constConfig"
local shopConfig = require "logic.config.shopConfig"
local equipConfig = require "logic.config.equip"
local formulaConfig = require "logic.config.equipFormula"
local furnitureLevelupConfg = require "logic.config.furnitureLevelup"
local systemConfig = require "logic.config.system"[0]
local itemConfig = require "logic.config.itemConfig"
local furnitureTalentConfig = require "logic.config.furnitureTalent"
local bagsystem = require "logic.system.bagsystem"
local tasksystem = require "logic.system.tasksystem"
local workshopsystem = require "logic.system.workshopsystem"
local msgCode = require "common.model.msgerrorcode"

local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.product)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.product)
end

local function getEquipHistoryData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.equipHistory)
end

local function saveEquipHistoryData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.equipHistory)
end


-- 图纸状态
local formulaState = {
    unlock = 0,-- 未解锁
    lock = 1,-- 已解锁
}


local milestoneTypeDef = {
    addEquipPrice = 1, -- 装备价值提升
    unlcokNewFormula = 2, -- 给予的图纸id
    subMakeTime = 3, -- 减少制造时间
    raiseQuality = 4, -- 提高品质概率
    subMaterial = 5, -- 减少材料
}

local TechTreeUtil = {}

TechTreeUtil.addition = {}


local __ShopDefine = {}
local G_ShopDefine = __ShopDefine

__ShopDefine.QUICKEN_TYPE = {
    PRODUCTION = 1,
    SHOP_EXTEND = 2,
    FURNITURE_UPGRADE = 3
}


local __ConfigDict = 
{
    -- [__OrderType.CUSTOMER_SELL] = orderCustomerEquipConfig,
    -- [__OrderType.HEOR_BUY] = orderHeroEquipConfig,
    -- [__OrderType.PRINCESS_BUY] = orderPrincessConfig,
    -- [__OrderType.WORKER_BASE_MATERIAL] = orderWorkerMaterialConfig,
    -- [__OrderType.WORKER_EQUIP] = orderWorkerEquipConfig,
}


local function getConfigBySellType(theType)
    return __ConfigDict[theType]
end


local function packFormula(id, data)
    local msg = {}
    msg.id = tonumber(id)
    msg.lastProductTime = data.lastProductTime or 0
    msg.isFavorite = data.isFavorite or false
    msg.nowMilestone = data.nowMilestone or 0
    msg.lockState = data.lockState or formulaState.unlock
    msg.productCount = data.productCount or 0
    msg.endTime = data.endTime or 0
    msg.flag = data.flag or 0

    return msg
end

local function packSlot(slotData)
    local slotMsg = {}
    slotMsg.index = slotData.index
    slotMsg.productionId = slotData.productionId
    slotMsg.startTime = tostring(slotData.startTime)
    slotMsg.totalTime = slotData.totalTime
    slotMsg.count = slotData.count

    return slotMsg
end

local function packProductData(make)
    local msg = {produtionSlotInfos = {}}
    msg.hasProductSlotNum = make.hasProductSlotNum

    for k, v in pairs(make.list or {}) do
        local slotMsg = packSlot(v)
        table.insert(msg.produtionSlotInfos, slotMsg)
    end

    return msg
end

local function updateHistoryEquipData(player, formulaId, args)
    args = args or {}
    local equpid = math.floor(formulaId / 10)
    
    local cfg = equipConfig[equpid]
    if cfg and cfg.stage == define.equipStage.normal then
        local datas = getEquipHistoryData(player)
        local cfgStep = cfg.rank
        local sportion = tostring(cfg.portion)

        if args.all then
            datas.posData = datas.posData or {}
            local posData = datas.posData
    
            local nowStep = posData[sportion] or 0
            if cfgStep > nowStep then
                 posData[sportion] = cfgStep
            end
           
            local step = datas.step or 0
            if cfgStep > step then
                datas.step = cfgStep
            end

            datas.unlockPosData = datas.unlockPosData or {}
            local unlockPosData = datas.unlockPosData
            local nowStep = unlockPosData[sportion] or 0
            if cfgStep > nowStep then
                unlockPosData[sportion] = cfgStep
           end

           return
        end

        if args.unlock then
            datas.unlockPosData = datas.unlockPosData or {}
            local unlockPosData = datas.unlockPosData
            local nowStep = unlockPosData[sportion] or 0
            if cfgStep > nowStep then
                unlockPosData[sportion] = cfgStep
           end
        else
            datas.posData = datas.posData or {}
            local posData = datas.posData
    
            local nowStep = posData[sportion] or 0
            if cfgStep > nowStep then
                 posData[sportion] = cfgStep
            end
           
            local step = datas.step or 0
            if cfgStep > step then
                datas.step = cfgStep
            end
        end




        saveEquipHistoryData(player)
    end
end


local function activeFormulaTask(player, pid, formulaId)
    local equipId = math.floor(formulaId / 10)
    local cfg = equipConfig[equipId]
    if not cfg then
        return
    end

    local keys = "activeEquip" .. cfg.portion
    tasksystem.updateProcess(player, pid, define.taskType[keys], {1}, define.taskValType.cover, {formulaId})
end

local function ReqMakeProInfo(player, pid, proto)
    local datas = getData(player)
    
    if not datas then
        print("ReqMakeProInfo no datas", pid)
        return
    end

    datas.list = datas.list or {} -- 图纸数据
    local list = datas.list

    datas.make = datas.make or {} -- 槽位数据
    local make = datas.make
    local ok = false

    if next(list) == nil then
        ok = true
        local formulaId = systemConfig.formulaInitial
        if formulaConfig[formulaId] then
            local sid = tostring(formulaId)
            list[sid]={lockState = formulaState.lock}
            activeFormulaTask(player, pid, formulaId)

            updateHistoryEquipData(player, formulaId, {all=1})
        end
        
    end

    if make.hasProductSlotNum == nil then
        ok = true
        make.useList = {}
        make.hasProductSlotNum = 1
        table.insert(make.useList, 1) -- 可以使用的槽索引
    end

    if ok then
        saveData(player)
    end
    
    
    local msgs = {product={}}
    for k, v in pairs(list) do
       table.insert(msgs.product, packFormula(k, v))
    end

    msgs.productData = packProductData(make)

    net.sendMsg2Client(player, ProtoDef.ResMakeProInfo.name, msgs)

end


local function ReqUnlockFormula(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqUnlockFormula no datas", pid)
        return
    end
    
    local id = proto.id
    local cfg = formulaConfig[proto.id]
    if not cfg then
        print("ReqUnlockFormula no cfg", pid, id)
        return
    end

    local list = datas.list
    if not list then
        print("ReqUnlockFormula no list", pid, id)
        return
    end

    local sid = tostring(id)
    local data = list[sid]
    if not data then
        print("ReqUnlockFormula data", pid, id)
        return
    end

    local state = formulaState.lock
    if data.lockState == state then
        print("ReqUnlockFormula yet lock", pid, id)
        return
    end

    -- if data.endTime then
    --     print("ReqUnlockFormula temp data", pid, id)
    --     return
    -- end

    local costItem = {}

    local costCnt = cfg.openCostScrollCount[2]
    if costCnt > 0 then
        table.insert(costItem, {id = cfg.openCostScrollCount[1],count = costCnt,type = define.itemType.item})
        if not bagsystem.checkAndCostItem(player, costItem) then
            return
        end
    end

    data.lockState = state

    updateHistoryEquipData(player, id, {unlock=1})

    saveData(player)

    local msgs = {id = id}
    msgs.product = packFormula(id, data)
    net.sendMsg2Client(player, ProtoDef.ResUnlockFormula.name, msgs)

    activeFormulaTask(player, pid, id)
end

local function getFurnitureEffect(player)
    local effect = {discountEnergy = 0,buyEquipment = 0,highAttribute={},moreAttribute = {},gather = {},recovertTime = 0,talk = 0}
    local datas = playermoduledata.getData(player, define.playerModuleDefine.furniture)
    local ws = workshopsystem.getDecorateData(player)
    
    for fid, v in pairs(ws) do
        local fConf = furnitureConfig[fid] 
        local lv = v[(fConf.roomId or 0)]
        if fConf and lv then
            local talentCfg = furnitureTalentConfig[fConf.furnitureTalent]
            if talentCfg and talentCfg.room == fConf.roomId then
                    effect.discountEnergy = effect.discountEnergy + (talentCfg.discountEnergy[lv] or 0)
                    effect.buyEquipment = effect.buyEquipment + (talentCfg.buyEquipment[lv] or 0)
                    effect.recovertTime = effect.recovertTime + (talentCfg.recovertTime[lv] or 0)
                    effect.talk = effect.talk + (talentCfg.talk[lv] or 0)
                
                local ha = talentCfg.highAttribute[lv] 
                if #(ha or {}) >= 2 then
                    effect.highAttribute[ha[1]] = ( effect.highAttribute[ha[1]]  or 0) + ha[2]
                end
                local ma = talentCfg.moreAttribute[lv] 
                if #(ma or {}) >= 2 then
                    effect.moreAttribute[ma[1]] = ( effect.moreAttribute[ma[1]]  or 0) + ma[2]
                end

                local gather = talentCfg.gather[lv]
                if #(gather or {}) >= 2 then
                    effect.gather[gather[1]] = ( effect.gather[gather[1]]  or 0) + gather[2]
                end
            end
        end
    end

    return effect
end

local function getTargetFormula(player, cfg)
    local effect =  _G.gluaFuncGetFurnitureEffect(player)
    local qualityWeight = cfg.qualityWeight
    local total = 0
    local weight = {}
    if util.getMaplength(effect.highAttribute) > 0 then
        for _,v in ipairs(qualityWeight) do
            local equipCfg = equipConfig[v[1]]
            if equipCfg and equipCfg.equipQuality == define.equipQuality.orange then
                local classify = define.equiportionType[equipCfg.portion]
                local addRd = effect.highAttribute[classify] or 0
                weight[v[1]] = (weight[v[1]] or 0) + v[2] + addRd
                total = total + v[2]

                for k,info in ipairs(qualityWeight) do
                    if info[1] ~= v[1] then
                        weight[info[1]] = (weight[info[1]] or 0) - (info[2] / (10000 - v[2])) *addRd
                    end
                end
            elseif equipCfg then
                total = total + v[2]
                weight[v[1]] = v[2] + (weight[v[1]] or 0)
            end 
        end
    else
        for k,v in pairs(qualityWeight) do
            local equipCfg = equipConfig[v[1]]
            if equipCfg then
                total = total + v[2]
                weight[v[1]] = v[2]
            end 
        end
    end

    local rd = math.random(1,total)
    for equipid,v in pairs(weight) do
        if rd <= v then
            return equipid
        end
        rd = rd - v
    end

    return 0
end

local function getProductNeedEquip(forlumaData, formulaConfig)
    if not formulaConfig then
        return {}
    end
    local cnt = forlumaData.productCount or 0
    local mileStone, makeCount
    for _, v in ipairs(formulaConfig.milestoneOpenEffect) do
        if v[2] == milestoneTypeDef.subNeedCnt and 0 >= v[1] then
            if not makeCount or v[1] > makeCount then
                makeCount = v[1]
                mileStone = v
            end
        end
    end

    local needEquip = formulaConfig.needEquip
    if mileStone then
        needEquip[1][2] = needEquip[1][2] - mileStone[3]
    end

    return needEquip
end

local function getManufactureReduceTime(forlumaCfg, forlumaData)
    local nowMilestone = forlumaData.nowMilestone or 0

    local subMakeTime = milestoneTypeDef.subMakeTime
    for k, v in ipairs(forlumaCfg.milestoneOpenEffect) do
        if v[2] == subMakeTime and nowMilestone >= k then
            return v[3]
        end 
    end


    return 0
end

local function getProductTime(player, forlumaCfg, forlumaData)

    local subVal = getManufactureReduceTime(forlumaCfg, forlumaData)
    
    local equipId = getTargetFormula(player, forlumaCfg)
    local equipCfg = equipConfig[equipId]
    if equipCfg then
        local classify = define.equiportionType[equipCfg.portion]
        local rdT = 0

        if classify == define.equipClass.weapon then
            rdT = _G.gluaFuncGetWorkShopEffect(player,define.MAP_TYPE.TEMPERED_STEEL) or 0
        elseif classify == define.equipClass.armor then
            rdT = _G.gluaFuncGetWorkShopEffect(player,define.MAP_TYPE.FINE_CRAF) or 0
        elseif classify == define.equipClass.decoration then
            rdT = _G.gluaFuncGetWorkShopEffect(player,define.MAP_TYPE.CAREFULLY) or 0
        end

        subVal = subVal + rdT
    end

    local outputTime = forlumaCfg.outputTime
    outputTime = outputTime - outputTime * (subVal / 10000)

    return math.floor(outputTime)
end

local function getMilestoneReduceMat(id, productionData)
    if productionData.lockState == formulaState.unlock then
        return {}
    end

    local fConfig = formulaConfig[id]
    local map = {}

    local nowMilestone = productionData.nowMilestone or 0
    local subMaterial = milestoneTypeDef.subMaterial

    for k, v in ipairs(fConfig.milestoneOpenEffect) do
        local needCount = v[1]
        local typeIndex = v[2]
        local effectValue = v[3]
        local effectValue2 = v[4]
        if typeIndex == subMaterial and nowMilestone >= k then
            map[effectValue] = (map[effectValue]  or 0 ) + effectValue2
        end
    end

    return map
end

local function getAddition()
    return 0
end



local function ReqStartProduct(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqStartProduct no datas", pid)
        return
    end
    
    local id = proto.productionId
    local cfg = formulaConfig[id]
    if not cfg then
        print("ReqStartProduct no cfg", pid, id)
        return
    end

    local list = datas.list
    if not list then
        print("ReqStartProduct no list", pid, id)
        return
    end

    local make = datas.make
    if not make then
        print("ReqStartProduct no list", pid, id)
        return
    end

    local useList = make.useList
    if not useList then
        print("ReqStartProduct no useList", pid, id)
        return
    end
    
    local leftUseIdx = #useList
    if leftUseIdx <= 0 then
        print("ReqStartProduct no leftUseIdx slot", pid, id)
        return
    end

    local sid = tostring(id)
    local forlumaData = list[sid]
    local endTime = forlumaData.endTime
    if endTime then
        local curTime = gTools:getNowTime()
        if curTime >= endTime then
            print("ReqStartProduct expire time", pid, id)
            return
        end
    else
        if not forlumaData or forlumaData.lockState == formulaState.unlock then
            print("ReqStartProduct no lock this fromula or lock", pid, id)
            return
        end
    end


    local costItem = {}
    local itemType = define.itemType.item
    for _, v in pairs(cfg.needMaterials) do
        local materialId = v[1]
        local costMaterialCount = v[2]
        local theItemConfig = itemConfig[materialId]
        if not theItemConfig then
            print("ReqStartProduct no theItemConfig", pid, id, materialId)
            return
        end

        local reduceMaterialData = getMilestoneReduceMat(id, forlumaData)
        local reduceMaterialCount = reduceMaterialData[materialId] or 0

        if reduceMaterialCount > 0 then
            costMaterialCount = costMaterialCount - reduceMaterialCount
            costMaterialCount = costMaterialCount > 0 and costMaterialCount or 0
        end


        if costMaterialCount > 0 then
            table.insert(costItem, { id = materialId, count = costMaterialCount,type=itemType })
        end
    end


    local equipId = getTargetFormula(player, cfg)
    local config = equipConfig[equipId]
    if not config then
        print("startProduct equip config not find id", pid, equipId)
        return
    end

    local del = {}
    local equipOne = getProductNeedEquip(forlumaData, cfg)
    if equipOne and #equipOne >= 2 then
        local id, needCount  = equipOne[1], equipOne[2]
        del[id] = {}
        
        local list = del[id]
        if needCount > 0 then
            for k, v in pairs(proto.uids) do
                local equip = bagsystem.getItemInfo(player, pid, v)
                if not equip then
                    print("startProduct no equip", pid, v)
                    return
                end

                local owner = equip.owner
                if owner and equip.ownerType ~= define.itemType.furniture then
                    print("startProduct have master", pid, v, owner)
                    return
                end
                
                table.insert(list, v)
            end
        end
    end

    if next(costItem) and not bagsystem.checkAndCostItem(player, costItem) then
        return
    end
    
    bagsystem.deleteEquipByUid(player, pid, del)


    local startTime = gTools:getNowTime()
    local newSlotIndex = useList[leftUseIdx]

    local totalTime = getProductTime(player, cfg, forlumaData)
    
    local spCfg = systemConfig.makeNeedTaskId

    if not tasksystem.taskIsCompleteByType(player, spCfg[1], define.taskTypeDef.newPerson) then
        totalTime = spCfg[2]
    end


    table.remove(useList)

    local data = 
    {
        index = newSlotIndex, 
        productionId = id, 
        startTime = startTime, 
        totalTime = totalTime, 
        quality = equipConfig.equipQuality or 1, 
        count = 1 
    }

    forlumaData.lastProductTime = startTime

    make.list = make.list or {}
    table.insert(make.list, data)

    saveData(player)

    
    local msgs = {}
    msgs.produtionSlotInfo = packSlot(data)
    net.sendMsg2Client(player, ProtoDef.ResStartProduct.name, msgs)

    if forlumaData.endTime then
        local ret = _G.gluaFuncUpdateFormulaNpcData(player, pid, forlumaData.sellId, 1)
        if ret then
            if forlumaData.flag == nil then
                list[sid] = nil
            else
                forlumaData.endTime = nil
                forlumaData.flag = nil
            end

            saveData(player)
        end
    end
end



local function getNodeEffctValue(addtype, classify)
    if TechTreeUtil.addition[addtype] == nil then 
        return nil 
    end
    
    return TechTreeUtil.addition[addtype][classify]
end


local function ReqExtendSlot(player, pid, proto)
    local isGold = proto.isGold
    local datas = getData(player)
    if not datas then
        print("ReqExtendSlot no datas", pid)
        return
    end
    local config = shopConfig[0]
    if not config then
        print("ReqExtendSlot shopConfig not find", pid)
        return
    end
    local make = datas.make
    if not make then
        print("ReqExtendSlot no list", pid)
        return
    end

    local slotId = make.hasProductSlotNum
    if slotId >= systemConfig.equipMakeNumber then
        print("ReqExtendSlot max slot id", pid)
        return
    end
    local nextId = slotId + 1
    local extendSlot
    for i, v in ipairs(config.extendSlotParam) do
        if nextId == v[1] then
            extendSlot = v
            break
        end
    end
    if not extendSlot then
        print("ReqExtendSlot slot shopConfig id", pid)
        return
    end
    local cost = {}
    if not isGold then
        local roleLv = player:getLevel()
        if  roleLv < (extendSlot[4] or 0) then
            print("ReqExtendSlot slot gold unlock level not eougth id", pid,roleLv,(extendSlot[4] or 0),nextId)
            return
        end

        cost = {count = extendSlot[2],type = define.itemType.currency,id = define.currencyType.gold}
    else
        cost = {count = extendSlot[3],type = define.itemType.currency,id = define.currencyType.jade}
    end

    if not bagsystem.checkAndCostItem(player, {cost}) then
        print("ReqExtendSlot slot shopConfig item not eougth", pid,nextId)
        return
    end
    
    make.hasProductSlotNum = nextId
    table.insert(make.useList, nextId)

    saveData(player)

    local msgs = {hasProductSlotNum=nextId,produtionSlotInfo={}}
    msgs.produtionSlotInfo = packSlot({})

    net.sendMsg2Client(player, ProtoDef.ResExtendSlot.name, msgs)

    tasksystem.updateProcess(player, pid, define.taskType.slotCnt, {1}, define.taskValType.add)
end

local function ReqFavoriteProduction(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqFavoriteProduction no datas", pid)
        return
    end

    local id = proto.id
    local list = datas.list
    if not list then
        print("ReqFavoriteProduction no list", pid, id)
        return
    end

    local sid = tostring(id)
    local data = list[sid]
    if not data then
        print("ReqFavoriteProduction no data", pid, id)
        return
    end

    local isTrue = proto.isTrue or false
    data.isFavorite = isTrue
    saveData(player)

end

-- 更新图纸里程碑 
local function updateFormulaMilestone(player, pid, formulaConfig, id, forlumaData, list)

    if forlumaData then
        local newCnt = (forlumaData.productCount or 0) + 1
        forlumaData.productCount = newCnt
    
        local nextIdx = (forlumaData.nowMilestone or 0) + 1
    
    
        local cfg = formulaConfig.milestoneOpenEffect
        local unlockType = milestoneTypeDef.unlcokNewFormula
        for idx = nextIdx, #cfg do
            local miles = cfg[idx]
            local needCount = miles[1]
            if newCnt >= needCount then
                forlumaData.nowMilestone = idx
    
                local lockId = miles[3]
                if lockId and (miles[2] == unlockType)  then
                    local sid = tostring(lockId)
                    local data = list[sid]
                    if not data or data.endTime then
                        bagsystem.addItems(player, {{id=lockId,count=1,type=define.itemType.item}}, define.rewardTypeDefine.notshow)
                    end
                end
            end
        end
    
        local msg = {}
        msg.product = packFormula(id, forlumaData)
        net.sendMsg2Client(player, ProtoDef.NotifyUpFormulaInfo.name, msg)
    
        local equipId = math.floor(id / 10)
        local cfg = equipConfig[equipId]
        if cfg then
            local keys = "equipProcess" .. cfg.portion
            tasksystem.updateProcess(player, pid, define.taskType[keys], {1}, define.taskValType.cover, {id, forlumaData.nowMilestone})
        end
    end

end

local function sendCollectData(player,code,slotData)
    local msgs = {}
    if slotData then
        msgs.produtionSlotInfo = packSlot(slotData) 
    else
        msgs.produtionSlotInfo = {}
    end
    msgs.code  = code
    net.sendMsg2Client(player, ProtoDef.ResCollectProduction.name, msgs)
end

local function collectProduction(player, pid, index, costEnergy, costGem)
    costEnergy = costEnergy or 0
    costGem = costGem or 0

    local datas = getData(player)
    if not datas then
        print("collectProduction no datas", pid)
        sendCollectData(player,msgCode.result.null)
        return
    end
    
    local make = datas.make
    if not make then
        print("collectProduction no list", pid)
        sendCollectData(player,msgCode.result.null)
        return
    end

    local makeList = make.list
    if not makeList then
        print("collectProduction no makeList", pid)
        sendCollectData(player,msgCode.result.null)
        return
    end

    local list = datas.list 
    if not list then
        print("collectProduction no list", pid)
        sendCollectData(player,msgCode.result.null)
        return
    end

    local slotData = nil
    local idx = nil
    for k, v in ipairs(makeList) do
        if v.index == index then
            slotData = v
            idx = k
            break
        end
    end

    if not slotData then
        print("collectProduction no slotData", pid, index)
        sendCollectData(player,msgCode.result.null)
        return
    end

    local forlumaId = slotData.productionId
    local sid = tostring(forlumaId)



    local cfg = formulaConfig[forlumaId]
    if not cfg then
        print("collectProduction no cfg", pid, index)
        sendCollectData(player,msgCode.result.null)
        return
    end

    local equipId = getTargetFormula(player, cfg)
    local config = equipConfig[equipId]
    if not config then
        print("collectProduction no config", pid, index)
        sendCollectData(player,msgCode.result.null)
        return
    end

    local costs = {}
    local nowTime = gTools:getNowTime()
    local costTime = slotData.totalTime
    local leftTime =  (slotData.startTime + costTime) - nowTime
    if costEnergy > 0 or costGem > 0 then
        if leftTime > 0 then
            local tempParam = { id = forlumaId, totalTime = costTime }
            if costEnergy > 0 then
                local calcCostEnergy = _G.gluaFuncgetQuickCostBaseVal(player,"Energy", G_ShopDefine.QUICKEN_TYPE.PRODUCTION, tempParam) * leftTime
                calcCostEnergy = math.ceil(calcCostEnergy)
                calcCostEnergy = calcCostEnergy <= 0 and 1 or calcCostEnergy
    
                --加速消耗的善意减少比例
                calcCostEnergy = gluaFuncgetManufactureSPReduceEnergy(player, calcCostEnergy, forlumaId)
                table.insert(costs,{id=define.currencyType.goodWill,count=calcCostEnergy,type=define.itemType.currency})

            else
                local costGem = _G.gluaFuncgetQuickCostBaseVal(player,"Gem", G_ShopDefine.QUICKEN_TYPE.PRODUCTION, tempParam) * leftTime
                costGem = math.ceil(costGem)
                costGem = costGem <= 0 and 1 or costGem

                table.insert(costs,{id=define.currencyType.jade,count=costGem,type=define.itemType.currency})

            end  
        end
    else
        if leftTime > 0 then
            local spCfg = systemConfig.makeNeedTaskId
            if tasksystem.taskIsCompleteByType(player, spCfg[1], define.taskTypeDef.newPerson) then
                print("collectProduction no complete", pid, index, forlumaId, nowTime, slotData.startTime+costTime, slotData.startTime,costTime)
                return
            end
        end
    end

    if #costs > 0 and  not bagsystem.checkItemEnough(player, costs) then
        print("checkItemEnough check not enougt")
        return
    end
    

    local count = 1 
    local rd = math.random(10000)
    local rdT = 0
    local classify = bagsystem.getEquipKind(config.portion)
    if classify == define.equipClass.weapon then
        rdT = _G.gluaFuncGetWorkShopEffect(player,define.MAP_TYPE.UNCANNY_WORKMANGSHIP) or 0
    elseif classify == define.equipClass.armor then
        rdT = _G.gluaFuncGetWorkShopEffect(player,define.MAP_TYPE.UNIQUE_INGENUIY) or 0
    elseif classify == define.equipClass.decoration then
        rdT = _G.gluaFuncGetWorkShopEffect(player,define.MAP_TYPE.INGENIOUS) or 0
    end

    if rdT > 0 and rd <= rdT then
        count = count + 1
    end 


    if bagsystem.addItems(player, {{id=equipId,type=define.itemType.equip,count=count}}, define.rewardTypeDefine.notshow) then
        return
    end

    bagsystem.costItems(player, costs)

    table.remove(makeList, idx)
    table.insert(make.useList, index)

    local forlumaData = list[sid]
    updateFormulaMilestone(player, pid, cfg, forlumaId, forlumaData, list)

    saveData(player)
    sendCollectData(player,msgCode.result.success,slotData)


    local portion = config.portion
    local kind = bagsystem.getEquipKind(portion)
    local pos = bagsystem.getEquipPos(portion)

    tasksystem.updateProcess(player, pid, define.taskType.makeEquip, {count}, define.taskValType.add, {config.equipQuality,kind,pos,equipId})
    tasksystem.updateProcess(player, pid, define.taskType.makeEquipState, {count}, define.taskValType.add, {config.rank})
    tasksystem.updateProcess(player, pid, define.taskType.makeEquipStateQuality, {count}, define.taskValType.add, {config.rank, config.stage, config.equipQuality})

    local keys = "makeEquipQuality" .. portion
    tasksystem.updateProcess(player, pid, define.taskType[keys], {count}, define.taskValType.add, {equipId})

    tasksystem.updateProcess(player, pid, define.taskType.makeForlumaId, {count}, define.taskValType.add, {config.belong})


end

local function ReqCollectProduction(player, pid, proto)
    collectProduction(player, pid, proto.index)
end


local function ReqQuickenProduct(player, pid, proto)
    local costEnergy = proto.costEnergy
    local costGem = proto.costGem
    local index = proto.index
    if (costEnergy == 0 and costGem == 0) or (index <= 0) then
        print("ReqQuickenProduct args err", pid, index, costGem, costEnergy)
        return
    end

    collectProduction(player, pid, index, costEnergy, costGem)

end


local function exchangeItemByFormulaid(player, itemCfg, count, itemList, tipItemRd)
    if #itemCfg.regain < 3  then
        return 
    end

    local id = itemCfg.regain[2]
    local type = define.itemType.item
    if id <= define.currencyType.max then
        type = define.itemType.currency
    end

    local cnt = itemCfg.regain[3] * count
    local item = {{
        type = type,
        count = cnt,
        id = id
    }}


end

local function UpdateTmpFormulaData(player, pid, itemId)
    local datas = getData(player)
    if not datas then
        return
    end

    local sid = tostring(itemId or 0)
    local list = datas.list or {}
    local data = list[sid]
    if not data then
        return
    end

    if data.endTime then
        if not data.flag then
            list[sid] = nil
        else
            data.endTime = nil
            data.flag = nil
        end
        saveData(player)
    end
end

local function AutoUseFormula(player, pid, itemList, tipItemRd, extra, args)
    args = args or {}
    extra = extra or {formaluaMsg = {}}
    local datas = getData(player)
    if not datas then
        print("AutoUseFormula no datas", pid)
        return
    end



    datas.list = datas.list or {} 
    local list = datas.list
    local ok = false

    local changeList = {}
    local formaluaMsg = extra.formaluaMsg
    local fight = extra.fight

    for itemId, itemCnt in pairs(itemList) do
        local cfg = itemConfig[itemId]
        local type = cfg.type
        if type == define.itemSubType.normalFormula or type == define.itemSubType.rareFormula then
            ok = true
            local sid = tostring(itemId)
            local mdata = list[sid]

            if mdata then
                if mdata.endTime then
                    if mdata.flag == nil then
                        mdata.flag = 1

                        itemCnt = itemCnt - 1
                        if itemCnt > 0 then
                            changeList[itemId] = itemCnt
                        end

                        itemList[itemId] = nil

                        local msgs = {}
                        msgs.product = packFormula(itemId, list[sid])
                    
                        table.insert(formaluaMsg, msgs)
                    else
                        changeList[itemId] = (changeList[itemId] or 0) + itemCnt
                    end
                else
                    changeList[itemId] = (changeList[itemId] or 0) + itemCnt
                end
            else
                local info = {lockState = formulaState.unlock}
                
                local endTime = args.endTime

                info.endTime = args.endTime
                info.sellId = args.sellId
                info.maxCnt = args.maxCnt
        
                list[sid] = info
                
        
                local msgs = {}
                msgs.product = packFormula(itemId, list[sid])
                
                if endTime then
                    net.sendMsg2Client(player, ProtoDef.NotifyUpFormulaInfo.name, msgs)
                end

                table.insert(formaluaMsg, msgs)

                updateHistoryEquipData(player, itemId)

                if fight then
                    tools.accRdCount(tipItemRd, itemId, 1)
                end

                itemCnt = itemCnt - 1
                if itemCnt > 0 then
                    changeList[itemId] = itemCnt
                end
            end

            itemList[itemId] = nil
        end
    end

    for k, v in pairs(changeList) do
        local itemCfg = itemConfig[k]
        if #itemCfg.regain == 3 then
            local id = itemCfg.regain[2]
            local type = define.itemType.item
            if id <= define.currencyType.max then
                type = define.itemType.currency
            end
        
            local cnt = itemCfg.regain[3] * v

            itemList[id] = (itemList[id] or 0) + cnt
        end
    end

    if ok then
        saveData(player)
    end
   

end


local function GetMilestoneGoldEffect(player, equipId)
    local sid = tools.getForlumaIdByEquipId(equipId)

    local formulaId = tonumber(sid)
    local cfg = formulaConfig[formulaId]
    if not cfg then
        return 0
    end


    local datas = getData(player) or {list={}}
    local list = datas.list

    local data = list[tostring(formulaId)]
    if not data then
        return 0
    end

    local nowMilestone = data.nowMilestone or 0

    local addEquipPrice = milestoneTypeDef.addEquipPrice
    for k, v in ipairs(cfg.milestoneOpenEffect) do
        if v[2] == addEquipPrice and nowMilestone >= k then
            return v[3]
        end 
    end


    return 0
end


local function showforlumadata(player, pid, args)
    pid = 72101935209036
    player = gPlayerMgr:getPlayerById(pid)
    local datas = getData(player)
    tools.ss(datas)
end

local function testtask(player, pid, args)
    pid = 72105157788467
    player = gPlayerMgr:getPlayerById(pid)
    bagsystem.addItems(player,{{id=10907071,count=1,type=1},{id=10908081,count=1,type=1},{id=1,count=1,type=define.itemType.currency},{id=2,count=1,type=define.itemType.currency},{id=3,count=1,type=define.itemType.currency},{id=4,count=1,type=define.itemType.currency}})
    -- -- local datas = playermoduledata.getData(player, define.playerModuleDefine.task)
    -- -- datas.list["6"] = {}
    -- --tasksystem.updateProcess(player, pid, define.taskType.makeEquipStateQuality, {1}, define.taskValType.add, {1, 1, 5})
    -- --tasksystem.updateProcess(player, pid, define.taskType.makeEquipState, {1}, define.taskValType.add, {1})
    -- --tasksystem.updateProcess(player, pid, define.taskType.businessCnt, {1}, define.taskValType.add)
    -- --tasksystem.updateProcess(player, pid, define.taskType.sellEquipCnt, {1}, define.taskValType.add,{11, 1, 1, 1})
    -- --tasksystem.updateProcess(player, pid, define.taskType.talk, {1, 0}, define.taskValType.add)
    -- --tasksystem.updateProcess(player, pid, define.taskType.sale, {1}, define.taskValType.add)
    -- --tasksystem.updateProcess(player, pid, define.taskType.disAndSell, {1}, define.taskValType.add)
    -- --tasksystem.updateProcess(player, pid, define.taskType.furnitureLevelType, {1}, define.taskValType.add, {6, 1})
    -- --tasksystem.updateProcess(player, pid, define.taskType.workshopTianfuDian, {0}, define.taskValType.cover)
    -- --tasksystem.updateProcess(player, pid, define.taskType.mainCheckpointType, {1}, define.taskValType.add, {5})
    -- --tasksystem.updateProcess(player, pid, define.taskType.mainCheckpointBox, {1}, define.taskValType.add)
    -- --tasksystem.updateProcess(player, pid, define.taskType.collectTime, {1}, define.taskValType.add)
    -- --tasksystem.updateProcess(player, pid, define.taskType.heroMingzuoLv, {1}, define.taskValType.add, nil, nil, {ret={["1"]=1}})
    -- --tasksystem.updateProcess(player, pid, define.taskType.accLogin, {1}, define.taskValType.add)
    -- --tasksystem.updateProcess(player, pid, define.taskType.heroJingyingLv, {1}, define.taskValType.add)
    -- tasksystem.updateProcess(player, pid, taskType, {1}, define.taskValType.cover, nil, nil, {ret=mdata})
end

_G.gluaFuncAutoUseFormula = AutoUseFormula
_G.gluaFuncGetFurnitureEffect = getFurnitureEffect
_G.gluaFuncGetMilestoneGoldEffect = GetMilestoneGoldEffect
_G.gluaFuncUpdateTmpFormulaData = UpdateTmpFormulaData

gm.reg("showforlumadata", showforlumadata)
gm.reg("testtask", testtask)


net.regMessage(ProtoDef.ReqMakeProInfo.id, ReqMakeProInfo, net.messType.gate)
net.regMessage(ProtoDef.ReqUnlockFormula.id, ReqUnlockFormula, net.messType.gate)
net.regMessage(ProtoDef.ReqStartProduct.id, ReqStartProduct, net.messType.gate)
net.regMessage(ProtoDef.ReqExtendSlot.id, ReqExtendSlot, net.messType.gate)
net.regMessage(ProtoDef.ReqFavoriteProduction.id, ReqFavoriteProduction, net.messType.gate)
net.regMessage(ProtoDef.ReqCollectProduction.id, ReqCollectProduction, net.messType.gate)
net.regMessage(ProtoDef.ReqQuickenProduct.id, ReqQuickenProduct, net.messType.gate)


