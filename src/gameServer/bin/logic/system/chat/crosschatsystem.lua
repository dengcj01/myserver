




local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"


local globalmoduledata = require "common.globalmoduledata"
local chatinterfacesystem = require "logic.system.chat.chatinterfacesystem"
local playersystem = require "logic.system.playersystem"

local function getGlobalData()
    return globalmoduledata.getGlobalData(define.globalModuleDefine.chat)
end

local function saveGlobalData()
    globalmoduledata.saveGlobalData(define.globalModuleDefine.chat)
end








local function ReqGetCrossChatData(srcServerId, proto)
    local channel = proto.channel
    local pid = proto.pid
    local pids = proto.pids

    local globalData = getGlobalData()

    if channel == define.chatChannelDef.world then
        local baseInfoList = {}
        local msgs = chatinterfacesystem.packAllChatData(channel, {{pid="0",mdata=globalData.wrold}}, baseInfoList)
        net.sendMsg2Game(srcServerId, ProtoDef.ResChatInfo.name, msgs, tonumber(pid))

        
    elseif channel == define.chatChannelDef.friend or channel == define.chatChannelDef.private then
        local msgs = {baseInfo = {}, pid = pid, channel = channel}
        local baseInfo = msgs.baseInfo

        for k, v in pairs(pids or {}) do
            local info = playersystem.getPlayerBaseInfo(v)
            table.insert(baseInfo, info)
        end
        
        --tools.ss(msgs)
        net.sendMsg2Game(srcServerId, ProtoDef.ResCrossPlayerBaseInfo.name, msgs)
    else
        return
    end


end



local function ReqCrossSendChat(srcServerId, proto)
    local pid,channel,content,otherPid = proto.pid, proto.channel, proto.content, proto.otherPid


    local globalData = getGlobalData()
    local mdata = {}

    local numPid = tonumber(pid)
    if channel == define.chatChannelDef.world then
        globalData.wrold = globalData.wrold or {}
        mdata = globalData.wrold
        local newMsg = chatinterfacesystem.addNewChat(mdata, numPid, content)
        saveGlobalData()

        local baseInfoList = {}
        local msg = chatinterfacesystem.packChatData(baseInfoList, channel, newMsg)

        local msgs = {channel=channel,data=msg, baseInfo = {baseInfoList[numPid]}}

        net.broadcastGame(ProtoDef.ResCrossSendChat.name, msgs)

        --tools.ss(msgs)
    elseif channel == define.chatChannelDef.friend or channel == define.chatChannelDef.private then
        local info = playersystem.getPlayerBaseInfo(otherPid)
        if not info then
            print("ReqCrossSendChat err", pid, otherPid)
            return
        end

        net.sendMsg2Game(info.serverId, ProtoDef.ReqAddNewChatData.name, proto)
    else
        print("ReqCrossSendChat err", pid, channel)
        return
    end


end



net.regMessage(ProtoDef.ReqGetCrossChatData.id, ReqGetCrossChatData, net.messType.master)
net.regMessage(ProtoDef.ReqCrossSendChat.id, ReqCrossSendChat, net.messType.master)