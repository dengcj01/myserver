




local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"

local systemConfig = require "logic.config.system"
local chatinterfacesystem = require "logic.system.chat.chatinterfacesystem"
local globalmoduledata = require "common.globalmoduledata"
local playermoduledata = require "common.playermoduledata"
local playersystem = require "logic.system.playersystem"


local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.chat)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.chat)
end

local function getGlobalData()
    return globalmoduledata.getGlobalData(define.globalModuleDefine.chat)
end

local function saveGlobalData()
    globalmoduledata.saveGlobalData(define.globalModuleDefine.chat)
end

local chatContentMaxLen = systemConfig[0].chatLen -- 聊天长度





local function ResCrossPlayerBaseInfo(srcServerId, proto)
    local pid, channel, baseInfo = proto.pid, proto.channel, proto.baseInfo
    local player = gPlayerMgr:getPlayerById(pid)
    if not player then
        return
    end

    --tools.ss(proto)


    local datas = getData(player) or {}

    local mdata = datas.friend
    if channel == define.chatChannelDef.private then
        mdata = datas.private
    end

    local pidList = {}
    for k, chatList in pairs(mdata or {}) do
        table.insert(pidList, {pid=tonumber(k), mdata = chatList})
    end

    

    local msgs = chatinterfacesystem.packAllChatData(channel, pidList, nil)
    msgs.baseInfo = baseInfo

    --tools.ss(msgs)
    net.sendMsg2Client(player, ProtoDef.ResChatInfo.name, msgs)
end

local function ReqChatInfo(player, pid, proto)
    local channel = proto.channel


    if channel == define.chatChannelDef.world then
        net.sendMsg2Master(ProtoDef.ReqGetCrossChatData.name, {pid=pid, channel=channel})
    elseif channel == define.chatChannelDef.friend or channel == define.chatChannelDef.private then
        local msgs = {pid=pid, channel = channel}

        local mdata = nil
        local datas = getData(player) or {}

        if channel == define.chatChannelDef.friend then
            mdata = datas.friend
        else
            mdata = datas.private
        end

        if next(mdata or {}) then
            msgs.pids = {}

            for k, v in pairs(mdata) do
                table.insert(msgs.pids, tonumber(k))
            end
 
            net.sendMsg2Master(ProtoDef.ReqGetCrossChatData.name, msgs)
            --tools.ss(msgs)
        else
            net.sendMsg2Client(player, ProtoDef.ResChatInfo.name, {channel=channel})
        end
    elseif channel == define.chatChannelDef.guild then
        local mdata = nil
        local globalData = getGlobalData()

        if channel == define.chatChannelDef.system then
            mdata = globalData.system
        elseif channel == define.chatChannelDef.guild then
            local guildId = player:getGuildId()
            if guildId <= 0 then
                print("ReqChatInfo no guildId", pid)
                return
            end

            local sguildId = tostring(guildId)

            local guildList = globalData.guildList or {}

            mdata = guildList[sguildId] or {}
        end

        local baseInfoList = {}
        local msgs = chatinterfacesystem.packAllChatData(channel, {{pid=0,mdata=mdata}}, baseInfoList)
    
        net.sendMsg2Client(player, ProtoDef.ResChatInfo.name, msgs)

        --tools.ss(msgs)
    elseif channel == define.chatChannelDef.system then
        local globalData = getGlobalData() or {}
        local system = globalData.system or {}

        local baseInfoList = {}
        local msgs = chatinterfacesystem.packAllChatData(channel, {{pid=0,mdata=system}}, baseInfoList)
    
        net.sendMsg2Client(player, ProtoDef.ResChatInfo.name, msgs)
    else
        print("ReqChatInfo err channel", pid, channel)
    end

end

local function addMyNewChat(player, pid, sendPid, channel, content, otherPid, datas)
    --datas = datas or getData(player)
    datas = playermoduledata.getPlayerModuleDataByPid(pid, 14)
    if not datas then
        print("addMyNewChat", pid, otherPid)
        return
    end

    local mdata = nil
    if channel == define.chatChannelDef.friend then
        datas.friend = datas.friend or {}
        mdata = datas.friend
    else
        datas.private = datas.private or {}
        mdata = datas.private
    end

    local sotherPid = tostring(otherPid)
    mdata[sotherPid] = mdata[sotherPid] or {}
    local chatList = mdata[sotherPid]

    local newMsg = chatinterfacesystem.addNewChat(chatList, sendPid, content)

    return newMsg
end

local function addOfflineChat(channel, pid, sendPid, content)
    local globalData = getGlobalData()
    local mdata = nil
    if channel == define.chatChannelDef.friend then
        globalData.friend = globalData.friend or {}
        mdata = globalData.friend
    else
        globalData.private = globalData.private or {}
        mdata = globalData.private
    end

    local spid = tostring(pid)
    mdata[spid] = mdata[spid] or {}
    local chatList = mdata[spid]

    local sendPid = tostring(sendPid)
    chatList[sendPid] = chatList[sendPid] or {}
    local list = chatList[sendPid]

    table.insert(list, content)

    saveGlobalData()
end

local function ReqSendChat(player, pid, proto)
    local channel,content,otherPid = proto.channel, proto.content, proto.otherPid
    local globalData = getGlobalData()
    if not globalData then
        print("ReqSendChat no global data", pid, channel)
        return
    end

    globalData.gag = globalData.gag or {}
    local gag = globalData.gag
    local spid = tostring(pid)
    local gagData = gag[spid] or {}
    local endTime = gagData.endTime
    local curTime = gTools:getNowTime()
    if endTime and curTime < endTime then
        tools.notifyClientTips(player, "您已被禁言")
        return
    end

    if channel == define.chatChannelDef.system then
        print("ReqSendChat cant not chat", pid, channel)
        return
    end

    local msgs = {code = 0, channel = channel}
    local len = string.len(content)
    if len > chatContentMaxLen then
        print("ReqSendChat max len", pid)
        return
    end

    content = gFilter:filterChat(content)

    --print("xxxxxxxxxxxxx",content)

    if channel == define.chatChannelDef.world then
        local msgs = {channel = channel, content = content, otherPid = otherPid, pid = pid}
        net.sendMsg2Master(ProtoDef.ReqCrossSendChat.name, msgs)
    elseif channel == define.chatChannelDef.friend or channel == define.chatChannelDef.private then
        if otherPid <= 0 then
            print("ReqSendChat err otherPid", pid, otherPid)
            return
        end

        local newMsg = nil
        newMsg = addMyNewChat(player, pid, pid, channel, content, otherPid)
        if newMsg then
            saveData(player)

            local baseInfoList = {}
            local msg = chatinterfacesystem.packChatData(baseInfoList, channel, newMsg)

            local msgs = {channel=channel,data=msg, baseInfo = baseInfoList[pid]}
            net.sendMsg2Client(player, ProtoDef.NotifyAddNewChat.name, msgs)
            --tools.ss(msgs)
        end

        local info = playersystem.getPlayerBaseInfo(otherPid)
        if info then
            local otherPlayer = gPlayerMgr:getPlayerById(otherPid)
            if otherPlayer then
                newMsg = addMyNewChat(otherPlayer, otherPid, pid, channel, content, pid)
                if newMsg then
                    saveData(otherPlayer)

                    local baseInfoList = {}
                    local msg = chatinterfacesystem.packChatData(baseInfoList, channel, newMsg)

        
                    net.sendMsg2Client(otherPlayer, ProtoDef.NotifyAddNewChat.name, {channel=channel,data=msg, baseInfo = baseInfoList[pid]})
                end
            else
                addOfflineChat(channel, otherPid, pid, content)
            end
        else
            local msgs = {channel = channel, content = content, otherPid = otherPid, pid = pid}
            net.sendMsg2Master(ProtoDef.ReqCrossSendChat.name, msgs)
        end
    elseif channel == define.chatChannelDef.guild then
        local guildId = player:getGuildId()
        if guildId <= 0 then
            print("ReqSendChat no guildId", pid)
            return
        end

        local sguildId = tostring(guildId)

        globalData.guildList = globalData.guildList or {}
        local guildList = globalData.guildList

        guildList[sguildId] = guildList[sguildId] or {}

        local mdata = guildList[sguildId]

        local newMsg = chatinterfacesystem.addNewChat(mdata, pid, content)
        saveGlobalData()

        local baseInfo = playersystem.getPlayerBaseInfo(pid)
        net.sendMsg2Client(player, ProtoDef.NotifyAddNewChat.name, {channel=channel,data=newMsg, baseInfo = baseInfo})

    else
        print("ReqSendChat err channel", pid, channel)
    end
end


local function ReqAddNewChatData(srcServerId, proto)
    local pid,channel,content,otherPid = proto.pid, proto.channel, proto.content, proto.otherPid

    local otherPlayer = gPlayerMgr:getPlayerById(otherPid)
    if otherPlayer then
        local newMsg = addMyNewChat(otherPlayer, otherPid, pid, channel, content, pid)
        if newMsg then
            saveData(otherPlayer)

            local baseInfoList = {}
            local msg = chatinterfacesystem.packChatData(baseInfoList, channel, newMsg)


            net.sendMsg2Client(otherPlayer, ProtoDef.NotifyAddNewChat.name, {channel=channel,data=msg, baseInfo = baseInfoList[pid]})
        end
    else
        addOfflineChat(channel, otherPid, pid, content)
    end
end

local function ResCrossSendChat(srcServerId, proto)
    local channel,data,baseInfo = proto.channel, proto.data, proto.baseInfo
    local msgs = {channel = channel, data = data, baseInfo = baseInfo[1]}

    net.broadcastPlayer(ProtoDef.NotifyAddNewChat.name, msgs)
    
end

local function processOfflineChatData(player, pid, channel, gdata)
    local spid = tostring(pid)
    local data = gdata[spid]
    if not data then
        return
    end


    local datas = getData(player)
    if not data then
        return
    end


    for sendPid, v in pairs(data) do
        sendPid = tonumber(sendPid)
        for _, content in ipairs(v) do
            addMyNewChat(player, pid, sendPid, channel, content, sendPid, datas)
        end
    end

    saveData(player)

    return true
end

local function login(player, pid, curTime, isfirst)
    local globalData = getGlobalData()
    if not globalData then
        return
    end

    local friendChat = globalData.friend or {}
    local privateChat = globalData.private or {}

    local ret1 = processOfflineChatData(player, pid, define.chatChannelDef.friend, friendChat)
    local ret2 = processOfflineChatData(player, pid, define.chatChannelDef.private, privateChat)
    if ret1 or ret2 then
        globalData.friend = nil
        globalData.private = nil
        saveGlobalData()
    end

end

local function forbidden(data)
    local ext = data.ext


    local endTime = ext.end_time or 0
    local opt = ext.type
    local globalData = getGlobalData()
    if not globalData then
        print("forbidden no globalData")
        return
    end

    globalData.gag = globalData.gag or {}
    local gag = globalData.gag
    if opt == 1 then -- 禁言
        if endTime <= 0 then
            print("forbidden", endTime)
            return
        end
    

        for k, v in pairs(data.role_id or {}) do
            local spid = tostring(v)
            gag[spid] = gag[spid] or {}
            local gagData = gag[spid]
            gagData.endTime = endTime
        end         
    else
        for k, v in pairs(data.role_id or {}) do
            local spid = tostring(v)
            gag[spid] = nil
        end
    end

    saveGlobalData()
end

local function systemNotice(data)
    local globalData = getGlobalData()
    globalData.system = globalData.system or {} 
    local mdata = globalData.system

    local first = data["0"]
    local showPos = first.show_pos
    local ret = tools.splitByNumber(showPos, ",")
    local content = first.content
    local res = tools.isInArr(ret, 3) -- 系统公告
    if res then
        local newMsg = chatinterfacesystem.addNewChat(mdata, 0, first.content)
        saveGlobalData()
    
        local msg = chatinterfacesystem.packChatData(nil, define.chatChannelDef.system, newMsg)
        local msgs = {channel = define.chatChannelDef.system, data = msg}

        net.broadcastPlayer(ProtoDef.NotifyAddNewChat.name, msgs)
    else
        tools.notifyAllClientTips(content, define.tipsType.paomadeng)
    end
end



local function showchat(player, pid, args)
    -- player = gPlayerMgr:getPlayerById(283204629321313)
    -- tools.ss(getData(player))

    -- local datas1 = playermoduledata.getPlayerModuleDataByPid(283204660872041, 14)
    -- tools.ss(datas1)

    tools.ss(getGlobalData())



end

local function ReqChatInfo1(player, pid, args)
    player = gPlayerMgr:getPlayerById(72105847010695)
    ReqChatInfo(player,283204629321313,{channel=define.chatChannelDef.guild})

end

local function sendchatdata(player, pid, args)
    if not gParseConfig:isGameServer() then
        return
    end

    player = gPlayerMgr:getPlayerById(72105847010695)
    --ReqSendChat(player,283204629321313,{channel=3,content="xxx"})
    --ReqSendChat(player,283204629321313,{channel=4,content="xxx1",otherPid=283204652591850})

    --ReqSendChat(player,283204629321313,{channel=4,content="sff",otherPid=283204660872041})
    --ReqSendChat(player,283204629321313,{channel=3,content="xxxddd"})
    --ReqSendChat(player,283204660872041,{channel=3,content="xxx"})
    ReqSendChat(player,72105847010695,{channel=define.chatChannelDef.guild,content="xxxdf"})
end

local function cleanchatdata(player, pid, args)
    local datas = playermoduledata.getPlayerModuleDataByPid(283204629321313, 14)
    tools.cleanTableData(datas)
    local datas1 = playermoduledata.getPlayerModuleDataByPid(283204660872041, 14)
    tools.cleanTableData(datas1)

    local gdata = getGlobalData()
    tools.cleanTableData(gdata)
end

local function savechatdata(player, pid, args)
    playermoduledata.saveDataByPid(283204660872041, 14)
end

event.reg(event.eventType.login, login)



gm.reg("showchat", showchat)
gm.reg("ReqChatInfo1", ReqChatInfo1)
gm.reg("sendchatdata", sendchatdata)
gm.reg("cleanchatdata", cleanchatdata)
gm.reg("savechatdata", savechatdata)

event.regHttp(event.optType.system, event.httpEvent[event.optType.system].systemNotice, systemNotice)
event.regHttp(event.optType.player, event.httpEvent[event.optType.player].forbidden, forbidden)

net.regMessage(ProtoDef.ReqChatInfo.id, ReqChatInfo, net.messType.gate)
net.regMessage(ProtoDef.ReqSendChat.id, ReqSendChat, net.messType.gate)



net.regMessage(ProtoDef.ResCrossSendChat.id, ResCrossSendChat, net.messType.game)
net.regMessage(ProtoDef.ResCrossPlayerBaseInfo.id, ResCrossPlayerBaseInfo, net.messType.game)
net.regMessage(ProtoDef.ReqAddNewChatData.id, ReqAddNewChatData, net.messType.game)