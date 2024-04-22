playerMgr = {}

function broadcastPlayer(protoName, msgs)
    if type(protoName) ~= "string" or type(msgs) ~= "table" then
        print("broadcaseAllPlayer err", protoName, msgs)
        return
    end

    local list = gPlayerMgr:getOnlinePlayers()
    for k, player in pairs(list) do
        gMainThread:sendMessage2GateClient(player:getSessionId(), player:getCsessionId(), protoName, msgs, 0)
    end
end

function sendMsg2Client(player, protoName, msgs)
    if type(player) ~= "userdata" or type(protoName) ~= "string" or type(msgs) ~= "table" then
        print("sendMsg2Client err", protoName, msgs)
        return
    end

    gMainThread:sendMessage2GateClient(player:getSessionId(), player:getCsessionId(), protoName, msgs, 0)
end

function sendMsg2Master(protoName, msgs)
    if not gParseConfig:isGameServer() then
        return
    end

    if type(msgs) ~= "table" then
        print("sendMsg2Master err", protoName, msgs)
        return
    end

    gMainThread:sendMessage2Master(gParseConfig:getMasterServerId(), protoName, msgs, 0)
end

function broadcastGame(protoName, msgs)
    if not gParseConfig:isMasterServer() or type(msgs) ~= "table" or type(protoName) ~= "string" then
        print("broadcastGame err", protoName, msgs)
        return
    end

    local list = gMainThread:getLogicServerList()
    for sessionId, _ in pairs(list) do
        gMainThread:sendMessage2GameClient(sessionId, protoName, msgs, 0)
    end
end

function sendMsg2Game(serverId, protoName, msgs, pid)
    if not gParseConfig:isMasterServer() or type(msgs) ~= "table" or type(protoName) ~= "string" then
        print("sendMsg2Game err", serverId, protoName, msgs, pid)
        return
    end

    local sessionId = gMainThread:getLogicSessionId(serverId)
    if sessionId == 0 then
        print("sendMsg2Game err1", serverId, protoName, msgs)
        return
    end

    pid = pid or 0

    gMainThread:sendMessage2GameClient(sessionId, protoName, msgs, pid)
end



function playerMgr.makeNotice(p1, p2, p3, p4, p5, p6)
    local info = {}
    info.param1 = p1 or 0
    info.param2 = p2 or 0
    info.param3 = p3 or 0
    info.param4 = p4 or 0
    info.param5 = p5 or 0
    info.param6 = p6 or 0
    return info
end

function playerMgr.addItem(player, itemList, desc, extra, rdType, notice, noMerge)
    if type(itemList) ~= "table" or not toolsMgr.isArr(itemList) or type(player) ~= "userdata" then
        print("addItem err", player:getPid())
        return
    end

    desc = desc or ""
    extra = extra or {}
    rdType = rdType or RewardTypeDefine.show
    notice = notice or {}



    local rdList = toolsMgr.megerReward(itemList)
    local sextra = toolsMgr.encode(extra)
    local res = player:addItems(rdList, desc, sextra)

    local msgs = {data = {}}
    local data = msgs.data
    
    local heroMsg = {data = {}}
    local newList = heroMsg.data

    for k, v in pairs(res) do
        table.insert(data, {id = k,count = v})
        if gCfgMgr:isHero(k) then
            local uid, heroInfo = heroMgr.getAnNewHero(player, k)
            local tmp = toolsMgr.clone(heroInfo)
            tmp.uid = uid
            table.insert(newList, tmp)
        end


        gTriggerAddItemEvent(player, k, v)
    end     
    
    if noMerge then
        msgs.data = itemList   
    end


    msgs.rdType = rdType
    msgs.param1 = notice.param1 or 0
    msgs.param2 = notice.param2 or 0
    msgs.param3 = notice.param3 or 0
    msgs.param4 = notice.param4 or 0
    msgs.param5 = notice.param5 or 0
    msgs.param6 = notice.param6 or 0

    gMainThread:sendMessage2GateClient(player:getSessionId(), player:getCsessionId(), ProtoDef.ResNoticeItemReward.name, msgs, 0)

    
    if next(heroMsg.data) then
        gMainThread:sendMessage2GateClient(player:getSessionId(), player:getCsessionId(), ProtoDef.ResNewHeroList.name, heroMsg, 0)
    end
end

function playerMgr.itemEnough(player, itemList)
    if type(itemList) ~= "table" or not toolsMgr.isArr(itemList) or type(player) ~= "userdata" then
        print("itemEnough err", player:getPid())
        return
    end
    local ret = toolsMgr.changeRewardArr2Map(itemList)
    local res = player:itemEnough(ret)

    return res
end

function playerMgr.costItem(player, itemList, desc, extra)
    if type(itemList) ~= "table" or not toolsMgr.isArr(itemList) or type(player) ~= "userdata" then
        print("costItem err", player:getPid())
        return
    end

    desc = desc or ""
    extra = extra or {}
    local sextra = toolsMgr.encode(extra)

    local ret = toolsMgr.changeRewardArr2Map(itemList)
    player:costItems(ret, desc, sextra)
end

function playerMgr.checkAndCostItem(player, itemList, desc, extra)
    if type(itemList) ~= "table" or not toolsMgr.isArr(itemList) or type(player) ~= "userdata" then
        print("checkAndCostItem err", player:getPid())
        return false
    end

    desc = desc or ""
    extra = extra or {}
    local sextra = toolsMgr.encode(extra)

    local ret = toolsMgr.changeRewardArr2Map(itemList)

    if player:itemEnough(ret) then
        player:costItems(ret, desc, sextra)
        return true
    end

    return false
end
