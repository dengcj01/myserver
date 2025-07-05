

local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"


local newGuideConfig = require "logic.config.newGuide"
local playermoduledata = require "common.playermoduledata"
local playersystem = require "logic.system.playersystem"


local systemConfig = require "logic.config.system"
local itemConfig = require "logic.config.itemConfig"
local npcGiftConfig = require "logic.config.npcGiftConfig"

local commonsystem = {}

local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.common)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.common)
end

-- local function ReqSaveNewPeopleGuide(player, pid, proto)
--     local datas = getData(player)
--     if not datas then
--         print("ReqSaveNewPeopleGuide err", pid)
--         return
--     end

--     datas.guide = datas.guide or {}
--     local guide = datas.guide
--     table.insert(guide, proto.id)


--     saveData(player)
-- end

-- local function ReqGetNewPeopleGuide(player, pid, proto)
--     local datas = getData(player) or {}
--     local guide = datas.guide or {}

--     local msgs = {data = guide}
--     net.sendMsg2Client(player, ProtoDef.ResGetNewPeopleGuide.name, msgs)
    
-- end

-- local function ReqSendNewPeopleGuideRd(player, pid, proto)
--     local id = proto.id

--     local cfg = newGuideConfig[id]
--     if not cfg then
--         print("ReqSendNewPeopleGuideRd err", pid, id)
--         return
--     end

--     local datas = getData(player)
--     if not datas then
--         print("ReqSendNewPeopleGuideRd no datas", pid, id)
--         return
--     end
    
--     datas.guideIds = datas.guideIds or {}
--     local guideIds = datas.guideIds
--     if tools.isInArr(guideIds, id) then
--         print("ReqSendNewPeopleGuideRd already recv", pid, id)
--         return
--     end

--     table.insert(guideIds, id)
--     saveData(player)

--     local rd = dropsystem.getDropItemList(cfg.drop)
--     local show = define.rewardTypeDefine.notshow
--     for k, v in pairs(rd) do
--         if v.type == define.itemType.hero then
--             show = define.rewardTypeDefine.show
--         end
--     end    

--     bagsystem.addItems(player, rd, show)
    
-- end

-- local function ReqPlayerChangeNameInfo(player, pid, proto)
--     local datas = getData(player) or {}
--     local msgs = {}
--     local changeNameInfo = datas.changeNameInfo or {}

--     msgs.cnt = changeNameInfo.cnt or 0

--     net.sendMsg2Client(player, ProtoDef.ResPlayerChangeNameInfo.name, msgs)
-- end


-- function gDbChangeNameRet(pid, code, name)
--     local player = gPlayerMgr:getPlayerById(pid)
--     if not player then
--         print("gDbChangeNameRet no player", pid)
--         return
--     end



--     if code == 0 then -- 正常
--         local datas = getData(player)
--         if not datas then
--             return
--         end
    
--         datas.changeNameInfo = datas.changeNameInfo or {}
--         local changeNameInfo = datas.changeNameInfo

--         local changeCnt = changeNameInfo.cnt or 0
--         if changeCnt > 0 then
--             local cnt = systemConfig[0].renameCost
--             bagsystem.costItems(player, {{id=define.currencyType.jade,type=define.itemType.currency,count=cnt}})
--         end
        
--         local newCnt = changeCnt + 1
--         changeNameInfo.cnt = newCnt
--         saveData(player)

--         player:setName(name)

--         local msgs = {name = name, cnt = newCnt}
--         net.sendMsg2Client(player, ProtoDef.ResChangeName.name, msgs)



   
--         return
--     end

--     local ret = "db错误"
--     if code == ChangeNameErrCodeRepeated then
--         ret = "名字重复"
--     end

--     tools.notifyClientTips(player, ret)
-- end


-- local function ReqChangeName(player, pid, proto)
--     local name = proto.name
--     local datas = getData(player)
--     if not datas then
--         return
--     end



--     local changeNameInfo = datas.changeNameInfo or {}

--     if not tools.fileterName(player, name) then
--         return
--     end

--     local len = string.len(name)
--     if len > systemConfig[0].nameLen then
--         tools.notifyClientTips(player, "名字太长")
--         return
--     end

--     local changeCnt = changeNameInfo.cnt or 0

--     if changeCnt > 0 then
--         local cnt = systemConfig[0].renameCost
--         if not bagsystem.checkItemEnough(player, {{id=define.currencyType.jade,type=define.itemType.currency,count=cnt}}) then
--             return
--         end
--     end

    
--     gPlayerMgr:changePlayerName(player, name)

-- end


-- local function cdkey(data)
--     local rd = {}
--     local pid = tonumber(data.role_id)

--     local player = gPlayerMgr:getPlayerById(pid)
--     if not player then
--         print("cdkey no player", pid)
--         return
--     end


--     for k, v in pairs(data.goods_list) do
--         local key = v.goods_id
--         local ret = tools.splitByNumber(key, "-")
--         if #ret <= 1 then
--             print("cdkey err", pid)
--             return
--         end
--         table.insert(rd, {id = ret[1], type = ret[2], count = tonumber(v.goods_num)})
--     end

--     if #rd then
--         bagsystem.addItems(player, rd)
--     else
--         print("cdkey no rd", pid)
--     end
    
-- end

-- local function ReqQuickBuy(player, pid, proto)
--     local id, count = proto.id, proto.count

--     if count <= 0 then
--         print("ReqQuickBuy zero", pid)
--         return
--     end

--     local conf = itemConfig[id]
--     if conf == nil then
--         print("ReqQuickBuy no conf", pid, id)
--         return
--     end

--     local convenientPurchase = conf.convenientPurchase
--     if convenientPurchase == nil then
--         print("ReqQuickBuy no convenientPurchase", pid, id)
--         return
--     end

--     if #convenientPurchase < 3 then
--         print("ReqQuickBuy no length", pid, id)
--         return
--     end


--     local costType = convenientPurchase[1]
--     local costId = convenientPurchase[2]
--     local price = convenientPurchase[3]

--     local cost = price * count



--     if id == define.currencyType.bossTili then
--         _G.gLuaFuncUpdateBossTiliTime(player, pid, id, count, price, costId, costType)
--         return
--     end

--     if not bagsystem.checkAndCostItem(player, {{id=costId,type=costType,count=cost}}) then
--         return
--     end

--     bagsystem.addItems(player, {{id=id,count=count,type=define.itemType.item}})
-- end

-- local function ReqSaveNpcGift(player, pid, proto)
--     local datas = getData(player)
--     if not datas then
--         print("ReqSaveNpcGift no datas", pid)
--         return
--     end

--     local ids = proto.ids
--     if not next(ids) then
--         print("ReqSaveNpcGift no ids", pid)
--         return
--     end

--     datas.gift = datas.gift or {}
--     local gift = datas.gift

--     for _, v in pairs(ids) do
--         local sid = tostring(v)
--         if gift[sid] ~= define.taskRewardDef.recv then
--             gift[sid] = define.taskRewardDef.noRecv
--         end
--     end

--     saveData(player)
-- end

-- local function ReqNpcGiftData(player, pid, proto)
--     local datas = getData(player)
--     if not datas then
--         print("ReqNpcGiftData no datas", pid)
--         return
--     end

--     local msgs = {ids = {}}
--     local ids = msgs.ids

--     local gift = datas.gift
--     for k, v in pairs(gift or {}) do
--         if v == define.taskRewardDef.noRecv then
--             table.insert(ids, tonumber(k))
--         end
--     end

--     net.sendMsg2Client(player, ProtoDef.ResNpcGiftData.name, msgs)
-- end

-- local function ReqNpcGiftRecv(player, pid, proto)
--     local ids = proto.ids
--     if not next(ids) then
--         print("ReqNpcGiftRecv no ids", pid)
--         return
--     end

--     local datas = getData(player)
--     if not datas then
--         print("ReqNpcGiftRecv no datas", pid)
--         return
--     end

--     datas.gift = datas.gift or {}
--     local gift = datas.gift

--     --local show = define.rewardTypeDefine.notshow
--     local ok = false

--     local itemList = {}
--     for _, id in pairs(ids) do
--         local npcGiftConfig = npcGiftConfig[id]
--         local sid = tostring(id)
--         if npcGiftConfig and gift[sid] ~= define.taskRewardDef.recv then
--             local drop = npcGiftConfig.drop
--             for _, v in pairs(drop) do
--                 table.insert(itemList, v)
--             end

--             --show = define.rewardTypeDefine.show
--             ok = true
--             gift[sid] = define.taskRewardDef.recv
--         end
--     end

--     if ok then
--         local items = dropsystem.getDropItemList(itemList)
--         bagsystem.addItems(player, items, define.rewardTypeDefine.notshow)
    
--         saveData(player)
--     end
-- end


-- local function chanplayergename(player, pid, args)
--     player = gPlayerMgr:getPlayerById(283204821213431)
--     ReqChangeName(player, 283204821213431, {name="浩浩1"})
-- end


-- local function gmReqSendNewPeopleGuideRd(player, pid, args)
--     pid = 72102474242207
--     player = gPlayerMgr:getPlayerById(pid)
--     bagsystem.addItems(player, {{id=8,type=5,count=1}}, define.rewardTypeDefine.notshow)
-- end

-- gm.reg("gmReqSendNewPeopleGuideRd", gmReqSendNewPeopleGuideRd)


-- gm.reg("chanplayergename", chanplayergename)
-- event.regHttp(event.optType.cdkey, event.httpEvent[event.optType.cdkey].cdkey, cdkey)



-- net.regMessage(ProtoDef.ReqGetNewPeopleGuide.id, ReqGetNewPeopleGuide, net.messType.gate)
-- net.regMessage(ProtoDef.ReqSaveNewPeopleGuide.id, ReqSaveNewPeopleGuide, net.messType.gate)
-- net.regMessage(ProtoDef.ReqSendNewPeopleGuideRd.id, ReqSendNewPeopleGuideRd, net.messType.gate)
-- net.regMessage(ProtoDef.ReqPlayerChangeNameInfo.id, ReqPlayerChangeNameInfo, net.messType.gate)
-- net.regMessage(ProtoDef.ReqChangeName.id, ReqChangeName, net.messType.gate)
-- net.regMessage(ProtoDef.ReqQuickBuy.id, ReqQuickBuy, net.messType.gate)
-- net.regMessage(ProtoDef.ReqSaveNpcGift.id, ReqSaveNpcGift, net.messType.gate)
-- net.regMessage(ProtoDef.ReqNpcGiftData.id, ReqNpcGiftData, net.messType.gate)
-- net.regMessage(ProtoDef.ReqNpcGiftRecv.id, ReqNpcGiftRecv, net.messType.gate)

return commonsystem

