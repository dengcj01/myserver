



local net = 
{
    messType = 
    {
        gate=1, -- 客户端消息
        game=2, -- 逻辑服执行
        master=3, -- 跨服执行        
    },

    messageList = {}
}




function net.regMessage(protoId, protoFunc, protoType)
    if type(protoFunc) ~= "function" then
        printTrace("net.regMessage err", protoId, protoFunc)
        return
    end

    net.messageList[protoType] = net.messageList[protoType] or {}
    local list = net.messageList[protoType]
    list[protoId] = protoFunc
end

-- 游戏服广播在线所有玩家
function net.broadcastPlayer(protoName, msgs)
    if type(protoName) ~= "string" or type(msgs) ~= "table" then
        print("broadcaseAllPlayer err", protoName, msgs)
        return
    end

    local list = gPlayerMgr:getOnlinePlayers()
    for k, player in pairs(list) do
        gMainThread:sendMessage2GateClient(player:getSessionId(), player:getCsessionId(), protoName, msgs, 0)
    end
end

-- 发消息给前端
function net.sendMsg2Client(player, protoName, msgs)
    if type(player) ~= "userdata" or type(protoName) ~= "string" or type(msgs) ~= "table" then
        print("sendMsg2Client err", player, protoName, msgs)
        return
    end

    gMainThread:sendMessage2GateClient(player:getSessionId(), player:getCsessionId(), protoName, msgs, 0)
end

-- 发消息给主连服
function net.sendMsg2Master(protoName, msgs)
    if not gParseConfig:isGameServer() then
        return
    end

    if type(msgs) ~= "table" then
        print("sendMsg2Master err", protoName, msgs)
        return
    end

    gMainThread:sendMessage2Master(gParseConfig:getMasterServerId(), protoName, msgs, 0)
end


-- 主连服广播给所有游戏服
function net.broadcastGame(protoName, msgs)
    if not gParseConfig:isMasterServer() or type(msgs) ~= "table" or type(protoName) ~= "string" then
        print("broadcastGame err", protoName, msgs)
        return
    end

    local list = gMainThread:getLogicServerList()
    for sessionId, _ in pairs(list) do
        gMainThread:sendMessage2GameClient(sessionId, protoName, msgs, 0)
    end
end

-- 主连服发消息给游戏服
function net.sendMsg2Game(serverId, protoName, msgs, pid)
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

-- 游戏服分发前端消息
function gDispatchGateClientMessage(player, pid, proto, protoId)
    local list = net.messageList[net.messType.gate] 
    local func = list[protoId]


    if type(func) ~= "function" then
        print("dispatchGateClientMessage err", pid, protoId)
        return
    end
    --print("dispatchGateClientMessage",player, pid, proto, protoId)
    func(player, pid, proto)
end

-- 游戏服分发主连服服消息
function gDispatchMasterMessage(srcServerId, pid, proto, protoId)
    local list = net.messageList[net.messType.game] 
    local func = list[protoId]
    if type(func) ~= "function" then
        print("dispatchMasterMessage err", srcServerId, protoId)
        return
    end
    --print("dispatchMasterMessage",srcServerId, pid, proto, protoId)
    func(srcServerId, proto)
end

-- 主连服分发游戏服消息
function gDispatchLogicGameMessage(srcServerId, pid, proto, protoId)
    local list = net.messageList[net.messType.master] 
    local func = list[protoId]
    if type(func) ~= "function" then
        print("dispatchLogicGameMessage err", srcServerId, protoId)
        return
    end

    --print("dispatchLogicGameMessage",srcServerId, pid, proto, protoId)
    func(srcServerId, proto)
end

return net