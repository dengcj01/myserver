



local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"


local httpsystem = require "logic.system.httpsystem"




local playersystem = {}

_G.allCachePlayers = _G.allCachePlayers or {}

local function updateBaseInfo(upInfo, baseInfo)
    for k, v in pairs(upInfo) do
        for kk, vv in pairs(v) do
            if baseInfo[kk] then
                baseInfo[kk] = vv
            end           
        end
    end    
end

function playersystem.updatePlayerBaseInfo(pid, upInfo, baseInfo)
    if gParseConfig:isMasterServer() then
        return
    end
    
    pid = tonumber(pid)
    local baseInfo = baseInfo or _G.allCachePlayers[pid]
    if not baseInfo then
        return
    end

    local sinfo = tools.encode(upInfo)
	gPlayerMgr:updatePlayerBaseInfo2Master(pid, sinfo)

    updateBaseInfo(upInfo, baseInfo)
end

function playersystem.getPlayerBaseInfo(pid)
    pid = tonumber(pid)
    local baseInfo = _G.allCachePlayers[pid] or {}

    return baseInfo
end



-- 服务器启动时加载基础玩家数据
function gLoadPlayers(data)
    local ret = tools.decode(data)
    for k, v in pairs(ret) do
        local pid = v.pid
        _G.allCachePlayers[pid] = v
    end

end

-- 玩家登入时
function gRegPlayerBaseInfo(data)
    local ret = tools.decode(data)
    local pid = ret.pid
    _G.allCachePlayers[pid] = ret
end

-- master调用
function gUpdatePlayerBaseInfo(pid, data)
    local baseInfo = _G.allCachePlayers[pid]
    if not baseInfo then
        return
    end

    local upInfo = tools.decode(data)
    updateBaseInfo(upInfo, baseInfo)
end

function gCheckHaveThisPlayer(pid)
    local ret = _G.allCachePlayers[pid]
    if ret then
        return true
    else
        return false
    end
end

local function ban(data)
    local ext = data.ext

    local reason = ext.reason
    local banTime = ext.end_time or 0
    local opt = ext.type
    if opt == 1 then -- 封号
        if banTime <= 0 then
            print("banbanbanban", banTime)
            return
        end
    
        for k, v in pairs(data.role_id or {}) do
            local v = tonumber(v)
            local player = gPlayerMgr:getPlayerById(v)
            if player then
                player:setBanTime(banTime)
                player:setBanReason(reason)
                gMainThread:forceCloseSession(player:getSessionId(), player:getCsessionId(), BackgroundKick)
            else
                local up = {{bantime=banTime},{banreason=reason}}
                local str = tools.encode(up)
                print("------------------------ban1", str)
                gPlayerMgr:updatePlayerBaseInfo(v, str)
            end
        end         
    else
        for k, v in pairs(data.role_id or {}) do
            local v = tonumber(v)
            local player = gPlayerMgr:getPlayerById(v)
            if not player then
                local up = {{bantime=0},{banreason=""}}
                local str = tools.encode(up)
                print("------------------------ban2", str)
                gPlayerMgr:updatePlayerBaseInfo(v, str)
            end

        end
    end
  
end



local function kick(data)
    local ext = data.ext
    local reason = ext.reason

    for k, v in pairs(data.role_id) do
        local player = gPlayerMgr:getPlayerById(v)
        if player then
            gMainThread:forceCloseSession(player:getSessionId(), player:getCsessionId(), BackgroundKick)
        end
    end   
end


local function sendPlayer2Houtai(player, pid, curTime)
    local info = {}


    local info = {}
    info.game_id = 1000
    info.channel_id = 1
    info.game_channel_id = 1100015
    info.platform_id = 1
    info.reg_server_id = player:getFromServerId()

    local serverId = gParseConfig:getServerId()
    info.server_id = serverId
    info.show_server_id = serverId
    info.user_id = player:getAccount()
    info.role_id = tostring(pid)
    info.role_name = player:getName()
    info.role_lv = player:getLevel()
    info.role_vip_lv = player:getVip()
    info.role_power = player:getPower()
    info.role_exp = player:getExp()

    local icon = player:getIcon()
    info.role_avatar = player:getIcon()
    if string.len(icon) == 0 then
        info.role_avatar = "1"
    end
    info.guild_id = player:getGuildId()
    info.time = curTime

    local res = tools.changeHttp(info)

    --print("xxxxxxxxxxx",res)
    --httpsystem.sendPostMessage(res, "log_login?")

    -- local lens = string.len(res)
    -- gMainThread:sendMessage2Http(res, lens)

end

local function login(player, pid, curTime, isfirst)

end

local function logout(player, pid, curTime)
    local up = {{logoutTime = curTime}}
    playersystem.updatePlayerBaseInfo(pid, up)
end




local function showcacheplayerfunc(player, pid, args)
    tools.sss(allCachePlayers)
    print("xxxx")
end

local function testbaseinfo(player, pid, args)
    local upInfo = {
        {vip = 10},
        {icon="aa"},
        {name="bb"},
        {power=100},
        {exp=1000},
        {level = 110},
        {headIcon=1},
        {guildId=1000},
        {serverId=11},
        {logoutTime=1751083240},
        {skin=1000},
        {bantime=1751083240},
        {banreason="test"},
        {title=111}
    }
    pid = 141721207554496
    playersystem.updatePlayerBaseInfo(pid, upInfo)
end


event.regHttp(event.optType.player, event.httpEvent[event.optType.player].ban, ban)
event.regHttp(event.optType.player, event.httpEvent[event.optType.player].kick, kick)

event.reg(event.eventType.login, login)
event.reg(event.eventType.logout, logout)

gm.reg("showcacheplayerfunc", showcacheplayerfunc)
gm.reg("testbaseinfo", testbaseinfo)







return playersystem

