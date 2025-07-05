local workshopsystem = {}

local workshopConfig = require "logic.config.workshop"
local workshopTalentConfig = require "logic.config.workshopTalent"
local heroConfig = require "logic.config.hero"
local talentNatureConfig = require "logic.config.talentNature"
local attributeConfig = require "logic.config.attribute"
local furnitureConfig = require "logic.config.furniture"
local alchemyConfig = require "logic.config.alchemy"
local net = require "common.net"
local define = require "common.define"
local herosystem = require "logic.system.hero.herosystem"
local gm = require("common.gm")
local playermoduledata = require "common.playermoduledata"
local bagsystem = require "logic.system.bagsystem"
local heroattributesystem = require "logic.system.hero.heroattributesystem"
local furnituresystem = require "logic.system.furnituresystem"
local tasksystem = require "logic.system.tasksystem"
local tools = require "common.tools"
local util = require "common.util"
local talentBusinessConfig = require "logic.config.talentBusiness"
local defaultLv =  1

local cacheWorkshopConfig = {}
for k, v in pairs(workshopConfig) do
    local talen = v.workshopTalen1
    cacheWorkshopConfig[talen] = k
end

-- 房间id定义
local roomIdDef =
{
    min = 1, --最小房间id
    max = 9 --最大房间id
}

local getTalentSlotStruct = function(id)
    return {
        id = id,
        level = 0
    }
end

local getHeroSlotStruct = function(id)
    return {
        id = id,
        level = 0,
        heroid = 0
    }
end

local getDecorateSlotStruct = function(id)
    return {
        id = id,
        level = 0,
        furnitureid = ""
    }
end

local getAlchemyStruct = function()
    return {
        itemid = 0,
        count = 0,
        startTime = 0
    }
end

-- 作用范围
local talentRange = {
    [1] = {0}, -- 1.自己
    [2] = {-1,1},-- 2.周围（左右各一个位置） 
    [3] = {1},-- 3.右方一个位置             
    [4] = {1,2}, -- 4.右方两个位置        
    [5] = {-1}, -- 5.左方一个位置         
    [6] = {-1,-2}, -- 6.左方二个位置      
    [7] = {-5,-4,-3,-2,-1,0,1,2,3,4,5}, -- 7.房内全部角色
    [8] = {-5,-4,-3,-2,-1,1,2,3,4,5}, -- 8.房内除自己以外全部角色
    [9] = {0}, --不包括的自己的其他门客数量对自己的加成
}

local FieldsEff = {
    [1] = "time",
    [2] = "double",
    [3] = "bargaining",
    [4] = "love",
    [5] = "priceUp",
    [6] = "buy",
    [7] = "weaponProduction",
    [8] = "additionalWeapons",
    [9] = "armorProduction",
    [10] = "additionalArmaor",
    [11] = "jewelryProduction",
    [12] = "additionalJewelry",
    [13] = "gatherPlace",
    [14] = "gatherOutput",
    [15] = "alchemy",
    [16] = "alchemyTime",
}

local function getConfig(roomid)
    local config = workshopConfig[roomid]
    return config
end

local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.workshop)
end
local function getfurnitureData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.furniture)
end

local function getHeroData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.hero)
end

local function saveWorkShop(player)
    playermoduledata.saveData(player, define.playerModuleDefine.workshop)
end

local function getCacheSpaceData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.cacheSpace)
end

local function saveCacheSpaceData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.cacheSpace)
end

local function getWorkShopData(player, roomid, data)
    local key = tostring(roomid)

    local data = data or getData(player)
    if not data.rooms then
        data.rooms = {}
    end

    local rooms = data.rooms

    if data[key] then
        rooms[key] = data[key]
        data[key] = nil
    end

    if not rooms[key] then
        rooms[key] = {
            roomid = roomid,
            level = defaultLv,
            demeanour = 0,
            demeanourLevel = 0,
            humor = 0,
            humorLevel = 0,
            talentSlot = {},
            heroSlot = {},
            decorateSlot = {},
            alchemy = getAlchemyStruct()
        }
    end

    if (rooms[key].level or 0) <= 0 then
        rooms[key].level = defaultLv
    end

    return rooms[key]
end

local function getWorkShopEffect(player, effectid, nowLevel, oldLevel)
    local wCfg = workshopTalentConfig[effectid]
    if not wCfg then
        return 0
    end

    local roomId = nil
    local idx = 1
    if effectid == 0 then
        return 0
    else
        if tools.isEven(effectid) then
            idx = 2
            roomId = cacheWorkshopConfig[effectid - 1]
        else
            roomId = cacheWorkshopConfig[effectid]
        end
    end
    
    if nowLevel == nil then
        local data = getWorkShopData(player, roomId)
        local talent = data.talentSlot[tostring(idx)]
        nowLevel = (talent and talent.level) or 0
    end


    local w = wCfg[FieldsEff[effectid]]
    if w then
        return w[nowLevel] or 0, w[oldLevel] or 0
    end

    return 0
    
end

local function init(player)
    local list = getData(player)
    if (list.init or 0) == 1 then
        return
    end

    for _, cfg in pairs(workshopConfig) do
        local data = getWorkShopData(player, cfg.id)
        local talentSlot = data.talentSlot
        -- 固定两个天赋槽位
        local tLen = util.getMaplength(talentSlot)
        if tLen < 2 then
            local indx = tLen + 1
            for id = indx, 2 do
                talentSlot[tostring(id)] = getTalentSlotStruct(id)
            end
        end

        local workerNumb = cfg.workerNumb
        local heroSlot = data.heroSlot
        local heroLen = util.getMaplength(heroSlot)
        if heroLen < workerNumb then
            local startIdx = heroLen + 1
            for id = startIdx, workerNumb do
                heroSlot[tostring(id)] = getHeroSlotStruct(id)
            end
        end

        local decorateSlot = data.decorateSlot
        local dLen = util.getMaplength(decorateSlot)
        local furnitureNumb = cfg.furnitureNumb
        if dLen < furnitureNumb then
            local startIdx = dLen + 1
            for id = startIdx, furnitureNumb do
                decorateSlot[tostring(id)] = getDecorateSlotStruct(id)
            end
        end
    end

    list.init = 1
    saveWorkShop(player)
end

local function writePack(data)
    local ws = {}

    ws.roomid = data.roomid
    ws.level = data.level
    ws.type = data.type
    ws.demeanour = data.demeanour
    ws.demeanourLevel = data.demeanourLevel
    ws.humorLevel = data.humorLevel
    ws.humor = data.humor
    ws.talentSlot = {}

    local talentSlot = data.talentSlot
    for k, v in pairs(talentSlot) do
        table.insert(ws.talentSlot, v)
    end

    ws.heroSlot = {}
    local heroSlot = data.heroSlot
    for k, v in pairs(heroSlot) do
        table.insert(ws.heroSlot, v)
    end

    ws.decorateSlot = {}
    local decorateSlot = data.decorateSlot
    for k, v in pairs(decorateSlot) do
        table.insert(ws.decorateSlot, v)
    end

    ws.alchemy = data.alchemy

    return ws
end

local function sendUPWorkShopData(player, data)
    local response = {}
    response.workshop = writePack(data)

    net.sendMsg2Client(player, ProtoDef.ResWorkShopUpSign.name, response)
end

function workshopsystem.getDecorateData(player)
    local tab = {}
    local data = getData(player)
    local furnData = playermoduledata.getData(player, define.playerModuleDefine.furniture) or {}
    local furnlist = furnData.furniture or {}

    local rooms = data.rooms or {}
    for _, v in pairs(rooms) do
        local decorateSlot = v.decorateSlot or {}
        for _, dec in pairs(decorateSlot) do
            local level = dec.level or 0
            if level > 0 then
                local uid = v.uid or ""
                local mdata = furnlist[uid] or {}
                local id = mdata.id
            
                if id then
                    if not tab[id] then
                        tab[id] = {}
                    end

                    tab[id][v.roomid] = level
                end
            end
        end
    end

    return tab
end

local function sendAllWorkShopData(player)

    local dataList = getData(player)
    local response = {
        workshop = {}
    }
    local workshop = response.workshop

    local rooms = dataList.rooms or {}
    for k, v in pairs(rooms) do
        table.insert(workshop, writePack(v))
    end

    net.sendMsg2Client(player, ProtoDef.ResWorkShop.name, response)
end

local function unlockSlot(player, roomid)
    local pid = player:getPid()
    local config = getConfig(roomid)
    if not config then
        print("unlockHeroSlot workshop  config not find roomid:", pid, roomid)
        return
    end
    local isSucc = false
    local data = getWorkShopData(player, roomid)
    -- 员工槽位增加
    local total = config.workerNumb
    local workerNumbUp = config.workerNumbUp or {}
    local level = data.level
    for k, v in pairs(workerNumbUp) do
        if v <= level then
            total = total + 1
        end
    end

    total = total - util.getMaplength(data.heroSlot)
    if total > 0 then
        for i = 1, total do
            local id = util.getMaplength(data.heroSlot) + 1
            data.heroSlot[tostring(id)] = getHeroSlotStruct(id)
        end
    end

    -- 摆件槽位增加
    local temptotal = config.furnitureNumb
    local furnitureNumbUp = config.furnitureNumbUp or {}
    for k, v in pairs(furnitureNumbUp) do
        if v <= level then
            temptotal = temptotal + 1
        end
    end

    local decorateSlot = data.decorateSlot
    temptotal = temptotal - util.getMaplength(decorateSlot)
    if temptotal > 0 then
        for i = 1, temptotal do
            local id = util.getMaplength(decorateSlot) + 1
            decorateSlot[tostring(id)] = getDecorateSlotStruct(id)
        end
    end

    saveWorkShop(player)
    sendUPWorkShopData(player, data)
end

local function ReqWorkShopRoomUp(player, pid, proto)
    local roomid = proto.roomid
    -- body
    local config = getConfig(roomid)
    if not config then
        print(" WorkShopLogic workshop config not find :", pid, roomid)
        return
    end

    local data = getWorkShopData(player, roomid)
    if not data then
        print("WorkShopLogic data room error  id:", pid, roomid)
        return
    end

    local level = data.level
    local nextLv = level + 1
    local cost = config.needCoin[level]
    if cost then
        local costItem = {{
            type = define.itemType.currency,
            count = cost[2],
            id = cost[1]
        }}
        if not bagsystem.checkAndCostItem(player, costItem) then
            print("ReqWorkShopRoomUp no checkAndCostItem")
            return
        end

    end

    if nextLv <= data.demeanourLevel then
        local talentSlot = data.talentSlot
        for k, v in pairs(talentSlot) do
            v.level = nextLv
        end
    end


    data.level = nextLv
    unlockSlot(player, roomid)
    saveWorkShop(player)
    sendUPWorkShopData(player, data)
end



local function clsAllTantentAttr(player, pid, roomid, talen1)
    local data = getWorkShopData(player, roomid)
    
    local heroNum = 0

    -- 加成比例
    local ids = {}

    local attrData = _G.HeroAttrData[pid] or {}
    -- 基础值
    local posHeroBase = {}
    local heroSlot = data.heroSlot or {}
    for _, v in pairs(heroSlot) do
        local heroid = v.heroid
        if heroid > 0 then
            if not posHeroBase[v.id] then
                posHeroBase[v.id] = {}
                ids[v.id] = {}
            end
            local base = posHeroBase[v.id]

            local talenData = attrData[heroid] or {}
            base[talen1] = (base[talen1] or 0) + talenData[talen1] or 0
            
            heroNum = heroNum + 1
        end
    end

    local wsCfg = getConfig(roomid)
    if not wsCfg then
        return {}
    end

    for _, v in pairs(heroSlot) do
        local heroid = v.heroid
        local id = v.id
        local heroCfg = heroConfig[heroid]

        if heroid > 0 and heroCfg and heroCfg.talentArrange[1] and heroCfg.talentArrange[1][1] then
            local talentRd = ids[id]
            --主经营加成
            if id == 1 then
                talentRd[talen1] = (talentRd[talen1] or 0) + wsCfg.buff
            end

            local talentNature = heroCfg.talentNature

            local talentBusId = heroCfg.talentArrange[1][1]
            local tbConfig = talentBusinessConfig[talentBusId]

            local tnCfg = talentNatureConfig[talentNature]

            --性格加成
            local nature = nil
            if tbConfig then
                nature = tbConfig.nature
            end
            if tnCfg and tnCfg.type and (nature == 0 or talentNature == nature) then
                local type = tnCfg.type
                for _, j in pairs(type) do
                    if roomid == j[1] then
                        talentRd[talen1] = (talentRd[talen1] or 0) + j[2]
                        break
                    end
                end
            end

            -- 主动天赋判断
            if tbConfig and herosystem.checkHasHeroTalent(player, heroid, define.talentName.arrange) then
                --站位影响
                local range = tbConfig.range
                local ra = talentRange[range]
                local position = tbConfig.position
                if ra and position == 0 or position == id then
            
                    for _, j in pairs(ra) do
                        local sid = tostring(id + j)
            
                        local nowHeroCfg = heroConfig[tonumber(sid)]
                        if nowHeroCfg then
                            local nowTalentNature = nowHeroCfg.talentNature 
                            local hero = data.heroSlot[sid]
                            --性格判断
                            if hero and hero.heroid > 0 and (nature == 0 or nowTalentNature == nature) then 
                                talentRd = ids[hero.id]
                                local numList = tbConfig.num
                                for _, m in pairs(numList) do
                                    local numTalent = m[1]
                                    local numRd = m[2]
                                    if numTalent == talen1 then
                                        local rate = 0
                                        if range == 9 then
                                            rate = numRd * (heroNum - 1)
                                        end
                                        if m[3] == 0 then
                                            talentRd[numTalent] = (talentRd[numTalent] or 0) - (numRd + rate)
                                        else
                                            talentRd[numTalent] = (talentRd[numTalent] or 0) + (numRd + rate)
                                        end
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local ret = {}
    for hid, v in pairs(posHeroBase) do -- {{房间id={[天赋id]=天赋基础值},...},...}
        local tinfo = ids[hid] -- {{房间id={[天赋id]=加成值},...},...}
        for tid, n in pairs(v) do
            if tinfo[tid] then
                v[tid] = (v[tid] or 0) * (1 + (tinfo[tid] / 10000))
            end
            ret[tid] = (ret[tid] or 0) + (v[tid] or 0)
        end
    end

    return ret
end



local function clsAttr(player, pid, roomid, data)
    local config = getConfig(roomid)
    if not config then
        print("clsAttr no config", pid)
        return
    end

    local talen = (config.need1 and config.need1[1] and config.need1[1][1]) or 0
    if talen == 0 then
        print("clsAttr no talen", pid)
        return
    end

    local talenNum = clsAllTantentAttr(player, pid, roomid, talen)
    local demeanour = talenNum[talen] or 0
    demeanour = math.floor(demeanour + 0.5)

    local demeanourLv = 0

    local need1 = config.need1
    for k, v in ipairs(need1) do
        local demeanourNum = v[2]
        if demeanour < demeanourNum then
            break
        end

        demeanourLv = demeanourLv + 1
        demeanour = demeanour - demeanourNum
    end
    
    data.humor = 0
    data.humorLevel = 0
    
    data.demeanour = demeanour

    if data.demeanourLevel ~= demeanourLv then
        data.demeanourLevel = demeanourLv
    else
        return
    end

    local wsCfg = workshopConfig[roomid]

    local roomLevel = data.level
    local maxLv = roomLevel
    local talentSlot = data.talentSlot
    for _, v in pairs(talentSlot) do
        v.level = demeanourLv
        if wsCfg and demeanourLv > 0 then
            --检查最大等级
            local talentLevelUp = wsCfg.talentLevelUp[roomLevel]
            if talentLevelUp then
                maxLv = talentLevelUp[v.id]
            end

            if demeanourLv > maxLv then
                v.level = maxLv
            end
        end
    end        
    


    local furnData = playermoduledata.getData(player, define.playerModuleDefine.furniture) or {}
    local furnList = furnData.furnitureList or {}

    local decorateSlot = data.decorateSlot
    for k, v in pairs(decorateSlot) do
        local furnitureid = v.furnitureid
        if furnitureid and furnitureid ~= "" then
            v.level = demeanourLv
            local fdata = furnList[v.furnitureid]
            local furnitureLeve = fdata.level or 1
            if fdata and demeanourLv > furnitureLeve then
                v.level = furnitureLeve
            end
        end
    end
end

local function unWearHero(player, pid, roomid, id)
    local data = getWorkShopData(player, roomid)
    local hero = data.heroSlot[tostring(id)]
    if not hero or hero.heroid <= 0 then
        print("unWearHero no hero", pid)
        return
    end

    local config = getConfig(roomid)
    if not config then
        print("unWearHero no config", pid)
        return
    end
 
    hero.heroid = 0
    clsAttr(player, pid, roomid, data)
    saveWorkShop(player)
    sendUPWorkShopData(player, data)
end



local function checkHero(player, pid, roomid, heroid)
    local list = getData(player)
    local sroomid = tostring(roomid)
    local rooms = list.rooms or {}
    for k, data in pairs(rooms) do
        if sroomid ~= k then
            local heroSlot = data.heroSlot
            for _, v in pairs(heroSlot) do
                if heroid == v.heroid then
                    unWearHero(player, pid, data.roomid, v.id)
                    return
                end
            end
        end
    end
end




local function ReqWorkShopAddHeros(player, pid, proto)
    local roomid, heros = proto.roomid, proto.heros or {}
    if roomid < roomIdDef.min or roomid > roomIdDef.max then
        print(" ReqWorkShopAddHeros roomid error", pid, roomid)
        return
    end

    local cacheSpaceData = getCacheSpaceData(player)
    if not cacheSpaceData then
        print(" ReqWorkShopAddHeros no cacheSpaceData", pid, roomid)
        return
    end

    local datas = getData(player) or {}
    local data = getWorkShopData(player, roomid, datas)


    for k, v in pairs(heros) do
        local heroid = v.heroid
        local isWear = v.isWear
        local id = v.index

        local heroSlotData = data.heroSlot[tostring(id)]

            
        if isWear and heroid > 0 and heroSlotData.heroid ~= heroid then
            checkHero(player, pid, roomid, heroid)
        end

        heroSlotData.heroid = heroid
    end

    clsAttr(player, pid, roomid, data)

    sendUPWorkShopData(player, data)

    saveWorkShop(player)

    local heroCnt = 0
    local alllv = 0

    local rooms = datas.rooms or {}
    for _, v in pairs(rooms) do
        local heroSlot = v.heroSlot or {}
        for _, info in pairs(heroSlot) do
            if info.heroid > 0 then
                heroCnt = heroCnt + 1
            end
        end

        local talentSlot = v.talentSlot or {}
        for k, mdata in pairs(talentSlot) do
            alllv = mdata.level + alllv
        end

        local decorateSlot = v.decorateSlot or {}
        for k, mdata in pairs(decorateSlot) do
            alllv = mdata.level + alllv
        end
    end


    tasksystem.updateProcess(player, pid, define.taskType.workShopAddCnt, {heroCnt}, define.taskValType.cover)

    tasksystem.updateProcess(player, pid, define.taskType.workshopTianfuDian, {alllv}, define.taskValType.cover)
end

local function unWorkShopDecorateData(player, pid, roomid, id)
    local data = getWorkShopData(player, roomid)
    if not data then
        print("unWorkShopDecorateData no data", pid, id, roomid)
        return
    end

    local decorateData = data.decorateSlot[tostring(id)]
    if not decorateData then
        print("unWorkShopDecorateData id err", pid, id, roomid)
        return
    end

    if decorateData.furnitureid == "" then
        print("unWorkShopDecorateData no furn", pid, roomid)
        return
    end

    decorateData.furnitureid = ""
    decorateData.level = 0

    saveWorkShop(player)
    sendUPWorkShopData(player, data)
end

local function ReqWorkShopAddOrUnWearDecorate(player, pid, proto)
    local roomid, id, furnitureid, isWear = proto.roomid, proto.index, proto.furnitureid, proto.isWear
    if not isWear then
        unWorkShopDecorateData(player, pid, roomid, id)
        return
    end

    local data = getWorkShopData(player, roomid)
    if not data then
        print("ReqWorkShopAddOrUnWearDecorate no data", pid, id, roomid)
        return
    end

    local decorateData = data.decorateSlot[tostring(id)]
    if not decorateData then
        print("ReqWorkShopAddOrUnWearDecorate id err", pid, id, roomid)
        return
    end

    local furnData = furnituresystem.getFurnitureDataByUid(player, furnitureid)
    if not furnData then
        print("ReqWorkShopAddOrUnWearDecorate no furnData", pid, id, roomid)
        return
    end

    local fid = furnData.id
    local config = furnitureConfig[fid]
    if not config then
        print("ReqWorkShopAddOrUnWearDecorate no fid", pid, id, roomid)
        return
    end

    if config.roomId ~= roomid then
        print("ReqWorkShopAddOrUnWearDecorate no math roomid", pid, id, roomid)
        return
    end

    if decorateData.furnitureid == furnitureid then
        print("ReqWorkShopAddOrUnWearDecorate same furnitureid", pid, id, roomid)
        return
    end

    local furnData = getfurnitureData(player)
    if not furnData then
        print("ReqWorkShopAddOrUnWearDecorate no furnData", pid, id, roomid)
        return
    end


    local demeanourLv = data.demeanourLevel
    decorateData.level = demeanourLv
    
    local furnList = furnData.furnitureList
    local fdata = furnList[furnitureid]
    local furnitureLeve = fdata.level or 1
    if fdata and demeanourLv > furnitureLeve then
        decorateData.level = furnitureLeve
    end

    decorateData.furnitureid = furnitureid

    saveWorkShop(player)
    sendUPWorkShopData(player, data)
end

local function ReqWorkShopAlchemy(player, pid, proto)
    local roomid, productid, count = proto.roomid, proto.productid, proto.count
    if productid <= 0 or count <= 0 then
        print(pid .. " ProductionAlchemy zero:" ,pid,count,productid)
        return
    end

    local data = getWorkShopData(player, roomid)
    local alchemy = data.alchemy
    if alchemy.itemid > 0 then
        print(pid .. " ProductionAlchemy product id not nil:" ..pid .." ".. alchemy.itemid)
        return
    end

    local config = alchemyConfig[productid]
    if not config then
        print(pid .. " ProductionAlchemy alchemy is not find  id::" .. productid)
        return
    end

    if data.level < config.needLevel then
        print(pid .. " ProductionAlchemy alchemy room level not enough  id::" .. productid)
        return
    end

    local costs = {}
    local useProp = config.useProp
    for k, v in pairs(useProp) do
        table.insert(costs, {
            type = define.itemType.item,
            id = v[1],
            count = v[2] * count
        })
    end

    if not bagsystem.checkAndCostItem(player, costs) then
        print(pid .. " ProductionAlchemy alchemy cost not enough  id::" .. productid)
        return
    end

    local totalT = config.workerNumb * count

    local rdT = _G.gluaFuncGetWorkShopEffect(player, define.MAP_TYPE.NINE_TURN) or 0

    local nowTime = gTools:getNowTime()
    totalT = math.floor(totalT - totalT * (rdT / 10000))
    local time = math.floor(nowTime + totalT);
    alchemy.itemid = productid
    alchemy.startTime = time
    alchemy.count = count

    saveWorkShop(player);
    sendUPWorkShopData(player, data)
end

local function ReqWorkShopCollectAlchemy(player, pid, proto)

    local roomid, productid = proto.roomid, proto.productid
    local data = getWorkShopData(player, roomid)
    local alchemy = data.alchemy
    local itemid = (alchemy.itemid or 0)
    if itemid <= 0 then
        print(pid .. " collectAlchemy product id not nil:",itemid)
        return
    end

    local config = alchemyConfig[productid]
    if not config then
        print(pid .. " collectAlchemy alchemy is not find  id::" .. productid)
        return
    end

    local totalT = alchemy.startTime
    if totalT > gTools:getNowTime() then
        print(pid .. " collectAlchemy alchemy time  Less than  id::" .. productid)
        return
    end

    local rdT = _G.gluaFuncGetWorkShopEffect(player, define.MAP_TYPE.WATER_FIRE) or 0
    local effect =  _G.gluaFuncGetFurnitureEffect(player)

    local makeProp = config.makeProp
    local count = makeProp[2] * alchemy.count

    rdT = rdT + (effect.gather[itemid] or 0)
    count = math.floor(count + count * (rdT / 10000))

    local awards = {{
        type = define.itemType.item,
        id = makeProp[1],
        count = count
    }}

    bagsystem.addItems(player, awards)
    alchemy.itemid = 0
    alchemy.startTime = 0
    alchemy.count = 0

    saveWorkShop(player, data, roomid);
    sendUPWorkShopData(player, data)

    tasksystem.updateProcess(player, pid, define.taskType.forgeCnt, {1}, define.taskValType.add, {itemid})
end

local function ReqWorkShop(player, pid, proto)
    init(player)
    sendAllWorkShopData(player)
end

local function ReqWorkShopSign(player, pid, proto)
    local roomid = proto.roomid
    local data = getWorkShopData(player, roomid)
    if not data then
        print("ReqWorkShopSign no roomid", pid)
        return
    end

    sendUPWorkShopData(player, data)
end

local function changeWorkShopEffect(player, pid, heroid)
    for k, v in pairs(workshopConfig) do
        local isBreak = false 
        local id = v.id
        if id > 0 then
            local data =  getWorkShopData(player, id)
            local heroSlot = data.heroSlot or {}
            for _, info in pairs(heroSlot) do
                if (info.heroid or 0)  == heroid then
                    isBreak = true
                    clsAttr(player, pid, id, data)
                    saveWorkShop(player)
                    break
                end
            end
        end

        if isBreak then
            break
        end
    end

end

local function CheckWorkShopFurnitureLv(player, pid, id, level)

    local data = getData(player)
    if not data then
        print("checkWorkShopFurnitureLv no data", pid)
        return
    end

    local rooms = data.rooms
    if not rooms then
        print("checkWorkShopFurnitureLv no rooms", pid)
        return
    end

    local ok = false
    local alllv = 0
    for _, roomData in pairs(rooms) do
        local decorateSlot = roomData.decorateSlot or {}
        for k, v in pairs(decorateSlot) do
            if id == v.furnitureid and roomData.demeanourLevel >= level then
                v.level = level
                ok = true
            end

            alllv = v.level + alllv
        end

        local talentSlot = roomData.talentSlot or {}
        for k, v in pairs(talentSlot) do
            alllv = v.level + alllv
        end
    end
    if ok then
        saveWorkShop(player)
    end

    tasksystem.updateProcess(player, pid, define.taskType.workshopTianfuDian, {alllv}, define.taskValType.cover)
end




local function showworkshop(player, pid, args)
    player = gPlayerMgr:getPlayerById(3518438940125069812)
    tools.ss(getData(player))
    local xx = getData(player)
    print("xxx")
end

local function showworkshop1(player, pid, args)
    pid = 72104286402582
    player = gPlayerMgr:getPlayerById(pid)
    ReqWorkShopAddHeros(player, pid, {roomid = 5,heros = {{ index = 2, heroid = 2, isWear = true}, { index = 1, heroid = 8, isWear = true}}})
    --


end


gm.reg("showworkshop", showworkshop)
gm.reg("showworkshop1", showworkshop1)

_G.gluaFuncGetWorkShopEffect = getWorkShopEffect
_G.gluaFuncChangeWorkShopEffect = changeWorkShopEffect
_G.CheckWorkShopFurnitureLv = CheckWorkShopFurnitureLv

net.regMessage(ProtoDef.ReqWorkShop.id, ReqWorkShop, net.messType.gate)
net.regMessage(ProtoDef.ReqWorkShopSign.id, ReqWorkShopSign, net.messType.gate)
net.regMessage(ProtoDef.ReqWorkShopRoomUp.id, ReqWorkShopRoomUp, net.messType.gate)
net.regMessage(ProtoDef.ReqWorkShopAddHeros.id, ReqWorkShopAddHeros, net.messType.gate)
net.regMessage(ProtoDef.ReqWorkShopAddOrUnWearDecorate.id, ReqWorkShopAddOrUnWearDecorate, net.messType.gate)
net.regMessage(ProtoDef.ReqWorkShopAlchemy.id, ReqWorkShopAlchemy, net.messType.gate)
net.regMessage(ProtoDef.ReqWorkShopCollectAlchemy.id, ReqWorkShopCollectAlchemy, net.messType.gate)

return workshopsystem
