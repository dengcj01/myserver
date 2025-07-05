


local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"

local globalmoduledata = require "common.globalmoduledata"

local playersystem = require "logic.system.playersystem"
local systemConfig = require "logic.config.system"

local function getGlobalData()
    return globalmoduledata.getGlobalData(define.globalModuleDefine.chat)
end

local function saveGlobalData()
    globalmoduledata.saveGlobalData(define.globalModuleDefine.chat)
end

local chatinterfacesystem = {}


local chatLimitLen = systemConfig[0].messageNumb -- 聊天数量上限

function chatinterfacesystem.packChatData(baseInfoList, channel, chatData)
    local msg = {content = chatData.content, sendTime = chatData.sendTime or 0}

    if channel ~= define.chatChannelDef.system then
        local pid = chatData.pid or 0
        if baseInfoList and pid > 0 then
            msg.pid = tostring(pid)
            local info = playersystem.getPlayerBaseInfo(pid)
            if baseInfoList[pid] == nil then
                baseInfoList[pid] = info
            end
        end
    end

    return msg
end

function chatinterfacesystem.packAllChatData(channel, pidList, baseInfoList)
    local msgs = {channel = channel, data = {}, baseInfo={}}
    local cnt = #pidList

    for i = 1, cnt do
        local pdata = pidList[i]
        msgs.data[i] = {data = {}, pid = pdata.pid}
        local data = msgs.data[i].data
        local mdata = pdata.mdata
        for k, v in ipairs(mdata or {}) do
            local chat = chatinterfacesystem.packChatData(baseInfoList, channel, v)
            table.insert(data, chat)
        end
    end

    if baseInfoList then
        msgs.baseInfo = tools.baseInfo2Arr(baseInfoList)
    end
    

    return msgs
end


function chatinterfacesystem.addNewChat(mdata, pid, content)
    pid = tonumber(pid)

    local len = #mdata
    if len >= chatLimitLen then
        table.remove(mdata, 1)
    end

    local newChat = 
    {
        content = content,
        sendTime = gTools:getNowTime(),
    }

    if pid > 0 then
        newChat.pid = pid
    end

    table.insert(mdata, newChat)

    return newChat
end

function chatinterfacesystem.cleanGuildChatData(sguildId)
    local globalData = getGlobalData()
    local guildList = globalData.guildList
    if guildList and guildList[sguildId] then
        guildList[sguildId] = nil
        saveGlobalData()    
    end

end

return chatinterfacesystem