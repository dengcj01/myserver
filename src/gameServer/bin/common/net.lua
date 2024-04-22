



netMgr = {messageList = {}}

netMgr.messType = 
{
    gate=1, -- 客户端消息
    game=2, -- 逻辑服执行
    master=3, -- 跨服执行
}


function netMgr.regMessage(protoId, protoFunc, protoType)
    if type(protoFunc) ~= "function" then
        printTrace("netMgr.regMessage err", protoId, protoFunc)
        return
    end

    netMgr.messageList[protoType] = netMgr.messageList[protoType] or {}
    local list = netMgr.messageList[protoType]
    list[protoId] = protoFunc
end


function dispatchGateClientMessage(player, pid, proto, protoId)
    local list = netMgr.messageList[netMgr.messType.gate] 
    local func = list[protoId]
    if type(func) ~= "function" then
        print("dispatchGateClientMessage err", pid, protoId)
        return
    end
    --print("dispatchGateClientMessage",player, pid, proto, protoId)
    func(player, pid, proto)
end

function dispatchMasterMessage(sourceId, pid, proto, protoId)
    local list = netMgr.messageList[netMgr.messType.game] 
    local func = list[protoId]
    if type(func) ~= "function" then
        print("dispatchMasterMessage err", sourceId, protoId)
        return
    end
    --print("dispatchMasterMessage",sourceId, pid, proto, protoId)
    func(sourceId, proto)
end

function dispatchLogicGameMessage(sourceId, pid, proto, protoId)
    local list = netMgr.messageList[netMgr.messType.master] 
    local func = list[protoId]
    if type(func) ~= "function" then
        print("dispatchLogicGameMessage err", sourceId, protoId)
        return
    end

    --print("dispatchLogicGameMessage",sourceId, pid, proto, protoId)
    func(sourceId, proto)
end