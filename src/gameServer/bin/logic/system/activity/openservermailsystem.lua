



local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"


local activitybasesystem = require "logic.system.activity.activitybasesystem"
local mailsystem = require "logic.system.mail.mailsystem"

local function getData(player, id)
    return activitybasesystem.getData(player, id)
end

local function saveData(player)
    activitybasesystem.saveData(player)
end

-- 邮件发送时间定义
local sendType =
{
    create = 1, -- 创号就发
    fixTme=2, -- 某个时间段发
}


local function sendMail(player, pid, isfirst, curTime, notice)
    local spid = tostring(pid)
    local actType = define.activeTypeDefine.mail
    local list = activitybasesystem.getSameTypeActivityIdList(player, actType)
    local ok = false
    local expireTime = curTime + mailsystem.getDefaultMailExpireTime()
    for k, id in pairs(list) do
        local datas = getData(player, id)
        local conf = activitybasesystem.getConfig(id, actType)
        if datas and conf then

            local times = datas.times
            for _, timeType in pairs(sendType) do
                local stimeType = tostring(timeType)
                local condData = times[stimeType] or {}

                if timeType == sendType.create then
                    for sk, data in pairs(condData) do
                        local pid = data.pid
                        if not pid[spid] then
                            pid[spid] = 1
                            ok = true
                            local cfg = conf.days[tonumber(sk)]
                            if cfg then
                                mailsystem.addPlayerMail(player, cfg.sendName, curTime, cfg.title, cfg.content, cfg.reward, nil, expireTime, nil, notice)
                            end
                        end
                    end
                elseif timeType == sendType.fixTme then
                    for sk, data in pairs(condData) do
                        local pid = data.pid
                        if not pid[spid] then
                            local time = data.time
                            if time and curTime >= time[1] and curTime < time[2] then
                                pid[spid] = 1
                                ok = true
                                local cfg = conf.days[tonumber(sk)]
                                if cfg then
                                    mailsystem.addPlayerMail(player, cfg.sendName, curTime, cfg.title, cfg.content, cfg.reward, nil, expireTime, nil, notice)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if ok then
        saveData(player)
    end
end

local function login(player, pid, curTime, isfirst)
    sendMail(player, pid, isfirst, curTime, false)
end

local function activitiOpen(player, pid, id, type, datas)
    local conf = activitybasesystem.getConfig(id, type)
    if not conf then
        return
    end

    datas.times = datas.times or {}
    local times = datas.times
    local curTime = gTools:getNowTime()

    for k, v in pairs(conf.days) do
        local condition = v.condition
        local scondition = tostring(condition)
        times[scondition] = times[scondition] or {}
        local condData = times[scondition]
        local sk = tostring(k)
        condData[sk] = {pid={}}
        local timeData = condData[sk]

        if condition == 2 then
            local time = v.time
            local year = time[1]
            local month = time[2]
            local day = time[3]

            local stime = gTools:getNowTimeByDate(year, month, day, 0, 0, 0) 
            local startTime = gTools:get0Time(stime)
            local duringTime = v.duringTime

            if duringTime == 0 then
                duringTime = 1
            end
            
            local endTime = startTime + 86400 * duringTime

            if curTime >= startTime and curTime < endTime then
                timeData.time = {startTime, endTime}
            end
        end
    end

    --tools.ss(datas)

    sendMail(player, pid, false, curTime, true)
end



event.reg(event.eventType.login, login)

activitybasesystem.reg(activitiOpen, define.activeTypeDefine.mail, define.activeEventDefine.open)