


local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"
local playermoduledata = require "common.playermoduledata"
local dropsystem = require "logic.system.dropsystem"
local bagsystem = require "logic.system.bagsystem"
local tasksystem = require "logic.system.tasksystem"

local orderGroupConfig = require "logic.config.orderGroupConfig"
local orderSystemConfig = require "logic.config.orderSystemConfig"
local equipConfig = require "logic.config.equip"
local systemConfig = require "logic.config.system"

local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.carriage)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.carriage)
end

local function getEquipHistoryData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.equipHistory)
end

local cacheEquipConfig = {}
for k, v in pairs(equipConfig) do
    if v.stage == define.equipStage.normal then
        local portion = v.portion
        cacheEquipConfig[portion] = cacheEquipConfig[portion] or {}
        local data = cacheEquipConfig[portion]

        local rank = v.rank
        data[rank] = v.priceGem
    end
end

local maxCarriagCnt = 4 -- 马车最大数量

-- 订单状态
local orderStatus = 
{
    default = 0, -- 未提交
    commit=1, -- 提交
}


-- 马车状态
local carriageStatus = 
{
    noprocess = 0, -- 未运行
    process=1, -- 已运行
}

local function forceRplace(range, diff, remaining)
    local cnt = #range
	for i=1, cnt do
        local nowVal = range[i]
		if nowVal + nowVal == remaining then
			table.insert(diff, nowVal)
			table.insert(diff, nowVal)
			break

		end
		
        local nextVal = range[i+1]
		if i ~= cnt and (nowVal + nextVal) >= remaining then
			table.insert(diff, nowVal)
			table.insert(diff, nextVal)
			break
		end
	end
end


local function createCarriage(player, pid, datas)
    local lv = player:getLevel()
    local checkPointId = _G.gluaFuncGetCheckpointId(player)
    local historyData = getEquipHistoryData(player)
    local normalStep = historyData.step or 0 -- 历史最高凡品阶数

    local cnt = #orderSystemConfig
    local conf = nil
    local groupCfg = nil
    for i=cnt, 1, -1 do
        local cfg = orderSystemConfig[i]

        local normalCfgVal = cfg.conditionEquip
        if normalStep > cfg.downNum then
            normalCfgVal = normalCfgVal - cfg.equipDown
        end

        if lv >= cfg.conditionLevel and checkPointId >= cfg.conditionBattleid and normalStep >= normalCfgVal then
            conf = cfg
            groupCfg = orderGroupConfig[i]
            break
        end
    end

    if not conf then
        conf = orderSystemConfig[1]
        groupCfg = orderGroupConfig[1]
    end

    local carriagLv = conf.lv
    local totalDifficulty = conf.totalDifficulty
    local range = conf.difficultyRadius
    local triggerAmend = conf.triggerAmend
    local diff = {}
    local total = 0
    local maxCnt = conf.orderMax

    -- 随机n个格子
    while total < totalDifficulty do
        local remaining = totalDifficulty - total
        local possible = {}
        local cnt = #diff

        if cnt == 3 and total <= triggerAmend then
            forceRplace(range, diff, remaining)
            break
        else
			for _, v in ipairs(range) do
	            if v <= remaining then
	                table.insert(possible, v)
	            end
	        end            
        end
        
        local index = math.random(#possible)
        local rval = possible[index]
    
        if #diff < maxCnt and (total + rval <= totalDifficulty) then
            table.insert(diff, rval)  
            total = total + rval
        end
    end


    local unlockPosData = historyData.unlockPosData or {} -- 历史部位数据
    local ret = {}
    local triggerFrequency = conf.triggerFrequency
    local refCnt = datas.refCnt or 0
    local amendNum = conf.amendNum


    local diffval = 0
    for k, v in pairs(diff) do
        diffval = diffval + v
    end

    if diffval ~= 8 then
        print("createCarriageerr", pid, groupCfg.id)
        tools.ss(diff)
    end

    for _, idx in ipairs(diff) do
        local groupConf = groupCfg.difficulty[idx]
        if not groupConf then
            print("createCarriage err", pid, carriagLv)
        else
            local maxWeight = 0
            local list = {}
            for k, v in ipairs(groupConf) do
                table.insert(list, maxWeight + v.weight)
                maxWeight = maxWeight + v.weight
            end 

            local rval = math.random(1, maxWeight)
            local key = nil
            for k, v in ipairs(list) do
                if rval <= v then
                    key = k
                    break
                end
            end

            if not key then
                print("createCarriage no key", pid, carriagLv, idx)
            else
                local idxCfg = groupConf[key]
                local conf = idxCfg.orderContent1
                local needPos = conf[1]
                local needStep = conf[2]
                local needCnt = conf[3]
                local rd = idxCfg.rewardId1

                -- 先触发保底
                local step = unlockPosData[tostring(needPos)]
                if not step then
                    conf = idxCfg.orderContent2
                    needPos = conf[1]
                    needStep = conf[2]
                    needCnt = conf[3]
                    rd = idxCfg.rewardId2
                else

                    if needStep - step > triggerFrequency and refCnt < amendNum then -- 生成的阶数过高,强制修正 
                        needStep = step + 1
                        refCnt = refCnt + 1
                    end
                end

                table.insert(ret, {content = {needPos, needStep, needCnt}, rd = rd})
            end
        end
    end

    datas.refCnt = refCnt

    return carriagLv, ret
end



local function packContent(data)
    data = data or {}
    
    local msg = {}
    for k, v in pairs(data) do
        local info = {}
        info.idx = tonumber(k)
        info.content = v.content
        info.status = v.status or orderStatus.default
        info.uids = v.uids or {}

        table.insert(msg, info)
    end

    return msg
end

local function packCarriage(uid, data)
    local info = {}
    info.uid = uid
    info.level = data.level or 0
    info.endTime = data.endTime or 0
    info.data = packContent(data.data)
    info.status = data.status or carriageStatus.noprocess
    info.idx = data.idx

    return info
end

local function AddNewCarrige(player, extra)
    local pid = player:getPid()

    local datas = getData(player)
    local level, ret = createCarriage(player, pid, datas)

    datas.data = datas.data or {}
    local mdata = datas.data

    if extra.isFuncopen then
        datas.orderCnt = (datas.orderCnt or 0) + 1
    end

    local uid = gTools:createUniqueId()
    uid = tostring(uid)

    local info = {}
    info.level = level
    info.data = ret
    info.idx = extra.idx

    mdata[uid] = info

    saveData(player)

    local msgs = {data={}}
    local data = msgs.data

    local msg = packCarriage(uid, info)

    table.insert(data, msg)

    net.sendMsg2Client(player, ProtoDef.NotifyAddNewCarriageOrder.name, msgs)
end


local function ReqCarriageInfo(player, pid, proto)
    local datas = getData(player)
    if not datas then
        return
    end

    local msgs = {data={}}
    local data = msgs.data
    for k, v in pairs(datas.data or {}) do
        local msg = packCarriage(k, v)

        table.insert(data, msg)
    end

    --tools.ss(msgs)
    net.sendMsg2Client(player, ProtoDef.ResCarriageInfo.name, msgs)
end


local function ReqCarriageRecv(player, pid, proto)
    local datas = getData(player)
    if not datas then
        return
    end

    local data = datas.data
    if not data then
        return
    end

    local uid = proto.uid

    local mdata = data[uid]
    if not mdata then
        print("ReqCarriageRecv no mdata", pid, uid)
        return
    end

    local curTime = gTools:getNowTime()
    local endTime = data.endTime or 0
    local status = mdata.status or carriageStatus.noprocess
    if status ~= carriageStatus.process then
        print("ReqCarriageRecv no process", pid, uid)
        return
    end

    if endTime > 0 and curTime < endTime then
        print("ReqCarriageRecv no com", pid, uid)
        return
    end

    local order = mdata.data
    local dropList = {}
    for k, v in pairs(order) do
        tools.mergeRewardArr(dropList, v.rd)
    end

    net.sendMsg2Client(player, ProtoDef.ResCarriageRecv.name, {uid=uid})

    local idx = mdata.idx
    data[uid] = nil
    saveData(player)
    AddNewCarrige(player, {idx=idx})

    local rd = dropsystem.getDropItemList(dropList)
    bagsystem.addItems(player, rd)




    tasksystem.updateProcess(player, pid, define.taskType.businessCnt, {1}, define.taskValType.add)
end

local function ReqCommitCarriageOrder(player, pid, proto)
    local datas = getData(player)
    if not datas then
        return
    end

    local data = datas.data
    if not data then
        return
    end

    local uid = proto.uid

    local mdata = data[uid]
    if not mdata then
        print("ReqCommitCarriageOrder no mdata", pid, uid)
        return
    end

    local order = mdata.data
    if not order then
        print("ReqCommitCarriageOrder no order", pid, uid)
        return
    end

    local idx = proto.idx
    local idxData = order[idx]
    if not idxData then
        print("ReqCommitCarriageOrder no idxData", pid, uid, idx)
        return
    end

    local status = idxData.status or orderStatus.default
    if status == orderStatus.commit then
        print("ReqCommitCarriageOrder no commit", pid, uid, idx, status)
        return
    end

    local lv = mdata.level
    local cfg = orderSystemConfig[lv]
    if not cfg then
        print("ReqCommitCarriageOrder no item", pid, uid)
        return
    end

    local uids = proto.uids
    if next(uids) == nil then
        print("ReqCommitCarriageOrder no item", pid, uid)
        return
    end

    local content = idxData.content
    local cnt = content[3]

    if cnt ~= #uids then
        print("ReqCommitCarriageOrder no mathc cnt", pid, uid, cnt)
        return
    end

    local needPos = content[1]
    local neddStep = content[2]
    local delList = {}
    local furnList = {}
    local frunType = define.itemType.furniture
    local carriType = define.itemType.carriage
    for k, v in pairs(uids) do
        local equip = bagsystem.getItemInfo(player, pid, v)
        if not equip then
            print("ReqCommitCarriageOrder no this equip", pid, v)
            return
        end

        if equip.owner and equip.ownerType ~= frunType then
            print("ReqCommitCarriageOrder have master", pid, v)
            return
        end

        local id = equip.id
        local config = equipConfig[id]
        if not config then
            print("ReqCommitCarriageOrder no config", pid, id)
            return
        end

        if config.portion ~= needPos then
            print("ReqCommitCarriageOrder no match pos", pid, id)
            return
        end

        if config.rank ~= neddStep then
            print("ReqCommitCarriageOrder no match step", pid, id)
            return
        end
    end

    for k, v in pairs(uids) do
        local equip = bagsystem.getItemInfo(player, pid, v)

        local owner = equip.owner
        local ownerType = equip.ownerType
        if owner and ownerType == frunType then
            furnList[owner] = furnList[owner] or {}
            local flist = furnList[owner]
            table.insert(flist, v)
        end

        equip.owner = uid
        equip.ownerType = carriType
        equip.idx = idx
    end

    idxData.status = orderStatus.commit
    idxData.uids = uids

    local allCommitflag = true

    for k, v in pairs(order) do
        if v.status ~= orderStatus.commit then
            allCommitflag = false
            break
        end

        for _, uid in pairs(v.uids or {}) do
            local info = bagsystem.getItemInfo(player, pid, uid)
            local id = info.id
            delList[id] = delList[id] or {}
            local del = delList[id]
            table.insert(del, uid)
        end
    end

    if next(furnList) then
        _G.gluaFuncDeleteFurnEquip(player, furnList)
    end

    local endTime = 0
    if allCommitflag then
        endTime = gTools:getNowTime() + cfg.orderAwardtime
        mdata.endTime = endTime - 1
        mdata.status = carriageStatus.process

        bagsystem.deleteEquipByUid(player, pid, delList)
    end

    saveData(player)

    local msgs = {}
    msgs.uid = uid
    msgs.uids = uids
    msgs.endTime = endTime
    msgs.idx = idx
    msgs.status = mdata.status

    net.sendMsg2Client(player, ProtoDef.ResCommitCarriageOrder.name, msgs)

    playermoduledata.saveData(player, define.playerModuleDefine.bag)
end

local function revertEquip(player, pid, order)
    local ok = false
    for _, v in pairs(order) do
        for _, uid in pairs(v.uids or {}) do
            local equip = bagsystem.getItemInfo(player, pid, uid)
            if equip then
                equip.owner = nil
                equip.ownerType = nil
                equip.idx = nil
                ok = true
            end
        end
    end

    if ok then
        playermoduledata.saveData(player, define.playerModuleDefine.bag)
    end
end

local function revertJade(player, pid, order)
    local count = 0
    for _, v in pairs(order) do
        local jadeCount = v.jade or 0
        if jadeCount > 0 then
            count = count + jadeCount
            v.jade = 0
            v.status = orderStatus.default
        end
    end

    if count > 0 then
        bagsystem.addItems(player, {{id = define.currencyType.jade, count = count, type = define.itemType.currency}})
    end
    
end

local function ReqRefCarriageOrder(player, pid, proto)
    local datas = getData(player)
    if not datas then
        return
    end

    local data = datas.data
    if not data then
        return
    end

    local uid = proto.uid

    local mdata = data[uid]
    if not mdata then
        print("ReqRefCarriageOrder no mdata", pid, uid)
        return
    end

    local status = mdata.status or carriageStatus.noprocess
    if status == carriageStatus.process then
        print("ReqRefCarriageOrder porcessed", pid)
        return
    end

    local endTime = mdata.endTime or 0

    if endTime ~= 0 then
        print("ReqRefCarriageOrder endTime ~= 0", pid, uid)
        return
    end

    local cfg = orderSystemConfig[mdata.level]
    if not cfg then
        print("ReqRefCarriageOrder no cfg", pid, uid)
        return
    end

    local costConf = cfg.refreshTimeexPend
    if not bagsystem.checkAndCostItem(player, {{id=costConf[2],type=costConf[1],count=costConf[3]}}) then
        return
    end

    revertJade(player, pid, mdata.data)

    local curTime = gTools:getNowTime()
    local refTime = cfg.refreshTime
    local clientTime = endTime

    clientTime = curTime + refTime
    mdata.endTime = clientTime - 1

    saveData(player)

    local msgs = {uid = uid, endTime = clientTime}

    net.sendMsg2Client(player, ProtoDef.ResRefCarriageOrder.name, msgs)
end



local function ReqSpeedCarriage(player, pid, proto)
    local datas = getData(player)
    if not datas then
        return
    end

    local data = datas.data
    if not data then
        return
    end

    local uid = proto.uid

    local mdata = data[uid]
    if not mdata then
        print("ReqSpeedCarriage no mdata", pid, uid)
        return
    end

    local cfg = orderSystemConfig[mdata.level]
    if not cfg then
        print("ReqSpeedCarriage no cfg", pid, uid)
        return
    end

    local curTime = gTools:getNowTime()
    local endTime = mdata.endTime or 0
    local speedUptime = cfg.speedUptime
    local costConf = cfg.speedUpexpend
    local clientTime = endTime
    local status = mdata.status or carriageStatus.noprocess

    if status == carriageStatus.noprocess and endTime <= 0 then
        print("ReqSpeedCarriage no endtime", pid, uid)
        return
    end

    local leftTime = curTime - endTime
    if leftTime >= 0 then
        print("ReqSpeedCarriage comed", pid)
        return
    end

    leftTime = math.abs(leftTime)
    local count = math.ceil(leftTime / speedUptime)

    if not bagsystem.checkAndCostItem(player, {{id=costConf[2],type=costConf[1],count=costConf[3] * count}}) then
        return
    end

    mdata.endTime = 0

    saveData(player)

    local msgs = {}
    msgs.uid = uid
    msgs.endTime = 0


    net.sendMsg2Client(player, ProtoDef.ResSpeedCarriage.name, msgs)

    if status == carriageStatus.noprocess then
        local reData = mdata.data
        revertEquip(player, pid, reData)
        revertJade(player, pid, reData)
        data[uid] = nil
        local idx = mdata.idx
        AddNewCarrige(player, {idx=idx})
    end 

    saveData(player)
end

local function newDay(player, pid, curTime)
    local datas = getData(player)
    if not datas then
        return
    end

    datas.refCnt = nil
    saveData(player)
end

local function playerLevelChange(player, pid, oldLevel, nowLevel)
    if not _G.gluaFuncFuntionIsOpen(player, define.functionOpen.bank) then
        return
    end

    local datas = getData(player)
    if not datas then
        return
    end

    datas.data = datas.data or {}
    local data = datas.data
    local cfg = systemConfig[0]
    local orderCnt = datas.orderCnt
    if orderCnt >= maxCarriagCnt then
        return
    end

    local msgs = {data={}}
    local sdata = msgs.data

    local nextIdx = orderCnt + 1

    for i=nextIdx, maxCarriagCnt do
        local needLv = cfg.openorderList[i-1]
        if needLv and nowLevel >= needLv then
            local level, ret = createCarriage(player, pid, datas)
            orderCnt = orderCnt + 1
            local uid = gTools:createUniqueId()
            uid = tostring(uid)

            local info = 
            {
                level = level,
                data = ret,
                idx = orderCnt
            }
            data[uid] = info

            local msg = packCarriage(uid, info)
            table.insert(sdata, msg)
        end
    end


    if(next(sdata)) then
        datas.orderCnt = orderCnt

        saveData(player)

        net.sendMsg2Client(player, ProtoDef.NotifyAddNewCarriageOrder.name, msgs)
    end

end

local function ReqCarriageTimeEnd(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqCarriageTimeEnd no datas", pid)
        return
    end

    local data = datas.data
    if not data then
        print("ReqCarriageTimeEnd no data", pid)
        return
    end

    local uid = proto.uid
    local mdata = data[uid]
    if not mdata then
        print("ReqCarriageTimeEnd no mdata", pid, uid)
        return
    end

    local endTime = mdata.endTime
    if not endTime then
        print("ReqCarriageTimeEnd no endTime", pid, uid)
        return
    end 


    local curTime = gTools:getNowTime()
    local leftTime = curTime - endTime
    if leftTime < 0 then
        leftTime = math.abs(leftTime)
        if leftTime >= 2 then
            print("ReqCarriageTimeEnd no end", pid, uid)
            return
        end
    end

    local idx = mdata.idx

    local reData = mdata.data
    revertEquip(player, pid, reData)
    revertJade(player, pid, reData)
    
    data[uid] = nil
    AddNewCarrige(player, {idx=idx})

    saveData(player)
end

local function ReqQuicklyComCarriage(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqQuicklyComCarriage no datas", pid)
        return
    end

    local data = datas.data
    if not data then
        print("ReqQuicklyComCarriage no data", pid)
        return
    end

    local uid = proto.uid
    local mdata = data[uid]
    if not mdata then
        print("ReqQuicklyComCarriage no mdata", pid, uid)
        return
    end

    local order = mdata.data
    if not order then
        print("ReqQuicklyComCarriage no order", pid, uid)
        return
    end

    local status = mdata.status or carriageStatus.noprocess
    if status == carriageStatus.process then
        print("ReqQuicklyComCarriage carriageStatus commit", pid, uid)
        return
    end

    local lv = mdata.level
    local cfg = orderSystemConfig[lv]
    if not cfg then
        print("ReqQuicklyComCarriage no cfg", pid, uid)
        return
    end

    local idx = proto.idx
    local idxData = order[idx]
    if not idxData then
        print("ReqQuicklyComCarriage no idxData", pid, uid, idx)
        return
    end

    local jadeCount = idxData.jade
    if jadeCount and jadeCount > 0 then
        print("ReqQuicklyComCarriage jabe exist", pid, uid, idx)
        return
    end

    if idxData.status == orderStatus.commit then
        print("ReqQuicklyComCarriage orderStatus commit", pid, uid, idx)
        return
    end

    local content = idxData.content
    local needPos = content[1]
    local neddStep = content[2]
    local cnt = content[3]
    if cacheEquipConfig[needPos] == nil or cacheEquipConfig[needPos][neddStep] == nil then
        print("ReqQuicklyComCarriage no cacheEquipConfig", pid, uid, idx)
        return
    end
    
    local cost = cacheEquipConfig[needPos][neddStep] * cnt

    if not bagsystem.checkAndCostItem(player, {{id = define.currencyType.jade, type= define.itemType.currency, count = cost}}) then
        return
    end

    idxData.jade = cost
    idxData.status = orderStatus.commit

    local delList = {}
    local ok = true
    for k, v in pairs(order) do
        local idxStatus = v.status or orderStatus.default
        if idxStatus == orderStatus.default then
            ok = false
            break
        end

        for _, uid in pairs(v.uids or {}) do
            local info = bagsystem.getItemInfo(player, pid, uid)
            local id = info.id
            delList[id] = delList[id] or {}
            local del = delList[id]
            table.insert(del, uid)
        end
    end

    local endTime = 0
    if ok then
        status = carriageStatus.process
        mdata.status = status
        endTime = gTools:getNowTime() + cfg.orderAwardtime
        mdata.endTime = endTime - 1

        bagsystem.deleteEquipByUid(player, pid, delList)
    end

    saveData(player)

    local msgs = {}
    msgs.uid = uid
    msgs.endTime = endTime
    msgs.idx = idx
    msgs.status = status

    net.sendMsg2Client(player, ProtoDef.ResQuicklyComCarriage.name, msgs)
end

local function showcarrige(player, pid, args)
    player = gPlayerMgr:getPlayerById(72101855110755)
    local datas = getData(player)
    tools.ss(datas)
end

local function cleancarrige(player, pid, args)
    player = gPlayerMgr:getPlayerById(3518438939847019155)
    local datas = getData(player)
    tools.cleanTableData(datas)
    saveData(player)
end

local function addcarrige(player, pid, args)
    player = gPlayerMgr:getPlayerById(3518438939847019155)
    AddNewCarrige(player, {idx=1, isFuncopen=1})
end

local function reqCarriageInfo(player, pid, args)
    --ReqCarriageInfo(player)
    player = gPlayerMgr:getPlayerById(3518438939847019155)
    pid = 3518438939847019155
    --ReqCarriageRecv(player, pid, {uid="3518438939849365854"})
    ReqRefCarriageOrder(player, pid, {uid="3518438939850329828"})
    ReqSpeedCarriage(player, pid, {uid="3518438939850329828"})
end

local function payerchangeaddcarrige(player, pid, args)
    player = gPlayerMgr:getPlayerById(3518438939847019155)
    playerLevelChange(player, 3518438939847019155, 0, 30)
    local datas = getData(player)
    local cnt = 0
    for k, v in pairs(datas.data) do
        cnt = cnt + 1
    end

end

local function payerchangeaddcarrige2(player, pid, args)
    pid = 72104959539032
    player = gPlayerMgr:getPlayerById(pid)
    local datas = getData(player)


    local data = datas.data


    local mdata = data["72105155737704"]

    --ReqQuicklyComCarriage(player, pid, {uid = "72105155737704", idx = 4})
    revertJade(player, pid, mdata.data)
end

event.reg(event.eventType.newDay, newDay)
event.reg(event.eventType.playerLevel, playerLevelChange)

_G.gluaFuncAddNewCarrige = AddNewCarrige


gm.reg("showcarrige", showcarrige)
gm.reg("cleancarrige", cleancarrige)
gm.reg("addcarrige", addcarrige)
gm.reg("reqCarriageInfo", reqCarriageInfo)
gm.reg("payerchangeaddcarrige", payerchangeaddcarrige)
gm.reg("payerchangeaddcarrige2", payerchangeaddcarrige2)

net.regMessage(ProtoDef.ReqCarriageInfo.id, ReqCarriageInfo, net.messType.gate)
net.regMessage(ProtoDef.ReqCarriageRecv.id, ReqCarriageRecv, net.messType.gate)
net.regMessage(ProtoDef.ReqCommitCarriageOrder.id, ReqCommitCarriageOrder, net.messType.gate)
net.regMessage(ProtoDef.ReqRefCarriageOrder.id, ReqRefCarriageOrder, net.messType.gate)
net.regMessage(ProtoDef.ReqSpeedCarriage.id, ReqSpeedCarriage, net.messType.gate)
net.regMessage(ProtoDef.ReqCarriageTimeEnd.id, ReqCarriageTimeEnd, net.messType.gate)
net.regMessage(ProtoDef.ReqQuicklyComCarriage.id, ReqQuicklyComCarriage, net.messType.gate)






