
local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"

local playermoduledata = require "common.playermoduledata"
local globalmoduledata = require "common.globalmoduledata"
local playersystem = require "logic.system.playersystem"
local bagsystem = require "logic.system.bagsystem"
local mailsystem = require "logic.system.mail.mailsystem"
local chatinterfacesystem = require "logic.system.chat.chatinterfacesystem"

local guildBasisConfig = require "logic.config.guildBasisConfig"[0]
local guildLevelConfig = require "logic.config.guildLevelConfig"




local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.activity)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.furniture)
end


local function getGuildData()
    return globalmoduledata.getGlobalData(define.globalModuleDefine.guild)
end

local function saveGuildData()
    globalmoduledata.saveGlobalData(define.globalModuleDefine.guild)
end

local function getLogData()
    return globalmoduledata.getGlobalData(define.globalModuleDefine.guildLog)
end

local function saveLogData()
    globalmoduledata.saveGlobalData(define.globalModuleDefine.guildLog)
end

local function getOtherData()
    return globalmoduledata.getGlobalData(define.globalModuleDefine.guildOther)
end

local function saveOtherData()
    globalmoduledata.saveGlobalData(define.globalModuleDefine.guildOther)
end

-- 工会日志类型定义
local guildOptDef =
{
    create = 1, -- 创建工会
    join = 2, -- 加入工会
    quit = 3, -- 退出工会
    changeName = 4, -- 修改工会名称/图标/边框
    changeNotice = 5, -- 修改公告/
    kick = 6, -- 踢人
    promotePresident = 7, -- 提升副会长
    freePresident = 8, -- 解除副会长职位
    abdicatePresident = 9, -- 转让会长职位
    changeLevel = 10, -- 升级工会
    offlineAbdicatePresident = 11, -- 离线解除转让会长职位
}

-- 工会申请类型定义
local guildApplyDef =
{
    noApply = -1, -- 不可申请
    none = 0, -- 成功
    full = 1, -- 人满
    fullApply = 2, -- 已满申请
    haveGuild = 3, -- 已有工会
    noFindGuild = 4, -- 找不到工会
    noFindCfg = 5, -- 找不到配置
    cding = 6, -- 冷却中
    apply = 7, -- 已申请
    noEnoughLv = 8, -- 等级不足
}

-- 工会职位更新定义
local guildJobChangeDef =
{
    president = 0, -- 转让会长
    upPresident = 1, -- 提升副会长职位
    dispresident = 2, -- 解除副会长职位
}

-- 工会成员登录或退出定义
local guildMemberLoginOrLogoutDef =
{
    login = 0, -- 登录
    logout = 2, -- 退出
}

local function packGuildBaseInfo(guildId, info)
    local msg = {}

    msg.guildId = guildId
    msg.name = info.name or ""
    msg.level = info.level or 1
    msg.exp = info.exp or 0
    msg.notice = info.notice or ""
    msg.icon = info.icon or 0
    msg.frame = info.frame or 0
    msg.preUid = info.preUid or ""
    msg.fUids = info.fUids or {}
    msg.needLv = info.needLv or 0
    msg.nameCnt = info.nameCnt or 0
    msg.jobCnt = info.jobCnt or 0
    msg.noticeCnt = info.noticeCnt or 0

    local applyOk = false
    if next(info.applys or {}) then
        applyOk = true
    end

    msg.applyOk = applyOk

    return msg
end

local function packMemberInfo(pid, share, enterTime, applyTime)
    share = share or {}
    enterTime = enterTime or 0

    local msg = tools.clone(playersystem.getPlayerBaseInfo(pid))
    local shareData = share[pid] or {}

    msg.dayShare = shareData.dayShare or 0
    msg.allShare = shareData.allShare or 0
    msg.enterTime = enterTime
    msg.applyTime = applyTime or 0    

    return msg
end

local function packGuildListInfo(guildId, info, endTime)
    local msg = {}

    msg.base = packGuildBaseInfo(guildId, info)
    msg.endTime = endTime or 0
    msg.cnt = info.cnt or 0

    return msg
end



local function ReqGuildListInfo(player, pid, proto)
    local guildId = player:getGuildId()
    if guildId > 0 then
        print("ReqGuildListInfo have guild", pid, guildId)
        return
    end

    local spid = tostring(pid)

    local gdata = getGuildData() or {}
    local otherData = getOtherData() or {}
    local applys = otherData.applys or {}
    local applyList = applys[spid] or {}


    local guildList = gdata.guildList or {}

    local curTime = gTools:getNowTime()
    local ok = false

    local msgs = {data = {}}
    local data = msgs.data
    for sguildId, v in pairs(guildList) do
        local endTime = applyList[sguildId] or 0
        if endTime > 0 and curTime >= endTime then
            applys[sguildId] = nil
            ok = true

            local papplys = v.applys or {}
            if papplys[spid] then
                papplys[spid] = nil
                v.applyCnt = v.applyCnt - 1
            end
        end

        local msg = packGuildListInfo(sguildId, v, endTime)
        table.insert(data, msg)
    end

    if next(applys) == nil then
        applys[spid] = nil
    end

    if ok then
        saveGuildData()
        saveOtherData()
    end

    net.sendMsg2Client(player, ProtoDef.ResGuildListInfo.name, msgs)
end




local function packGuildMemInfo(memList, share)
    share = share or {}
    local msg = {}
    for k, v in pairs(memList or {}) do
        local baseMsg = packMemberInfo(k, share, v)
        table.insert(msg, baseMsg)
    end

    return msg  
end

local function packGuildAllInfo(guildId, info, share, enterCd)
    local msg = {}
    msg.base = packGuildBaseInfo(guildId, info)
    msg.mem = packGuildMemInfo(info.mem, share)
    msg.enterCd = enterCd or 0

    return msg
end

local function ReqGuildInfo(player, pid, proto)
    local guildId = player:getGuildId()
    local sguildId = tostring(guildId)

    local spid = tostring(pid)

    local gdata = getGuildData() or {}
    local otherData = getOtherData() or {}
    local applys = otherData.applys or {}
    local applyList = applys[spid] or {}

    local guildList = gdata.guildList or {}
    local guildData = guildList[sguildId] or {}

    otherData.cdData = otherData.cdData or {}

    local cdData = otherData.cdData

    local enterCd = cdData[spid]
    
    local curTime = gTools:getNowTime() 
    if enterCd and curTime >= enterCd then
        cdData[spid] = nil
        enterCd = 0
        saveOtherData()
    end

    local msgs = {}
    msgs.data = packGuildAllInfo(sguildId, guildData, otherData.share, enterCd)

    net.sendMsg2Client(player, ProtoDef.ResGuildInfo.name, msgs)
end

local function ReqGuildApplyList(player, pid, proto)
    local guildId = player:getGuildId()
    if guildId <= 0 then
        print("ReqGuildApplyList not in guild", pid)
        return
    end

    local sguildId = tostring(guildId)
    local gdata = getGuildData() or {}
    local guildList = gdata.guildList or {}
    local guildData = guildList[sguildId]

    if not guildData then
        print("ReqGuildApplyList not find guild", pid)
        return
    end


    local spid = tostring(pid)
    local fUids = guildData.fUids or {}
    if guildData.preUid ~= spid and (not tools.isInArr(fUids, spid)) then  
        print("ReqGuildApplyList no authority", pid)
        return
    end

    local curTime = gTools:getNowTime()

    local otherData = getOtherData() or {}
    local papplys = otherData.applys or {}

    local msgs = {data = {}}
    local data = msgs.data

    local curTime = gTools:getNowTime()
    local ok = false

    local applyCnt = guildData.applyCnt or 0
    local applys = guildData.applys or {}
    for k, v in pairs(applys) do
        if curTime >= v then
            applyCnt = applyCnt - 1
            ok = true

            local applyList = papplys[k] or {}
            applyList[sguildId] = nil

            if next(applyList) == nil then
                papplys[k] = nil
            end

            applys[k] = nil
        else
            local msg = packMemberInfo(k, nil, nil, v)
            table.insert(data, msg)
        end
    end

    if ok then
        guildData.applyCnt = applyCnt

        saveGuildData()
        saveOtherData()
    end

    net.sendMsg2Client(player, ProtoDef.ResGuildApplyList.name, msgs)

end

local function ReqGuildLogInfo(player, pid, proto)
    local guildId = player:getGuildId()
    if guildId <= 0 then
        --print("ReqGuildLogInfo not in guild", pid)
        return
    end

    local sguildId = tostring(guildId)
    local logData = getLogData() or {}
    local guildLog = logData[sguildId] or {}

    local msgs = {logs = guildLog.logs or {}}

    net.sendMsg2Client(player, ProtoDef.ResGuildLogInfo.name, msgs)
end



local function addLog(sguildId, logData, logMsg, opt, params)
    logData[sguildId] = logData[sguildId] or {}
    local guildLog = logData[sguildId]

    guildLog.logs = guildLog.logs or {}

    local logs = guildLog.logs
    local cnt = guildLog.cnt or 0

    if cnt >= guildBasisConfig.guildLogsNum then
        table.remove(logs, 1)
    else
        cnt = cnt + 1
        guildLog.cnt = cnt
    end

    local curTime = gTools:getNowTime()

    table.insert(logs, {params = params, opt = opt, optTime = curTime})
    table.insert(logMsg, {params = params, opt = opt, optTime = curTime})
end



local function cleanGuildApply(guildData, spids, otherApplys, sguildId)
    local applys = guildData.applys or {}
    for spid, _ in pairs(spids) do
        if otherApplys then
            local data = otherApplys[spid] or {}
            data[sguildId] = nil

            if next(data) == nil then
                otherApplys[spid] = nil 
            end
        end

        if applys[spid] then
            applys[spid] = nil
            guildData.applyCnt = guildData.applyCnt - 1
        end
    end
end


local function delApplyByPids(guildList, applys, spid)
    local applyList = applys[spid]
    for sguildId, _ in pairs(applyList or {}) do
        local guildData = guildList[sguildId]
        if guildData then
            cleanGuildApply(guildData, {[spid]=1})
        end
    end

    applys[spid] = nil

end

local function notifyMySelfEnterGuild(player, sguildId, guildData, share)
    local msgs = {}
    msgs.data = packGuildAllInfo(sguildId, guildData, share)

    net.sendMsg2Client(player, ProtoDef.NotifyMySelfEnterGuild.name, msgs)
end

local function notifyAddNewMemEnterGuild(memList, msgs, spid)
    for k, v in pairs(memList or {}) do
        if k ~= spid then
            local player = gPlayerMgr:getPlayerById(tonumber(k))
            if player then
                net.sendMsg2Client(player, ProtoDef.NotifyAddNewMemEnterGuild.name, msgs)
            end
        end
    end
end

local function notifyAllMemberAddLogs(memList, logMsg)
    for k, v in pairs(memList or {}) do
        local player = gPlayerMgr:getPlayerById(tonumber(k))
        if player then
            net.sendMsg2Client(player, ProtoDef.NotifyAddNewGuildLog.name, logMsg)     
        end
    end
end

local function notifyGuildJobUpdate(memList, preUid, fUids, active, optUid)
    for k, v in pairs(memList) do
        local player = gPlayerMgr:getPlayerById(tonumber(k))
        if player then
            net.sendMsg2Client(player, ProtoDef.NotifyGuildJobUpdate.name, {preUid = preUid, fUids = fUids, active = active, uid = optUid})
        end
    end
end


local function enterGuild(player, spid, sguildId, guildData, guildList, otherData, opt, curTime)
    local guildId = tonumber(sguildId)
    local baseInfo = playersystem.getPlayerBaseInfo(spid)
    local name = baseInfo.name

    guildData.cnt = (guildData.cnt or 0) + 1

    local memList = guildData.mem

    memList[spid] = curTime

    local logMsg = {logs = {}}


    local logData = getLogData() or {}
    local logLimit = guildBasisConfig.guildLogsNum

    delApplyByPids(guildList, otherData.applys or {}, spid)

    local share = otherData.share or {}

    local npid = tonumber(spid)
    local baseInfo = playersystem.getPlayerBaseInfo(npid)
    playersystem.updatePlayerBaseInfo(npid, {guildId = guildId}, baseInfo)

    tools.sendOfflinePlayerInfo2Master(npid, baseInfo)

    if player then
        player:setGuildId(guildId)

        notifyMySelfEnterGuild(player, sguildId, guildData, share)
    else

        local up = {{guildid = guildId}}
        local str = tools.encode(up)
        gPlayerMgr:updatePlayerBaseInfo(npid, str)
    end


    if opt ~= guildOptDef.create then
        addLog(sguildId, logData, logMsg.logs, opt, {name})

        local addMsg = {mem = packMemberInfo(spid, share, curTime)}
        notifyAddNewMemEnterGuild(memList, addMsg, spid)

        notifyAllMemberAddLogs(memList, logMsg)
    end
    
    
end


local function ReqOnekeyEnterGuild(player, pid, proto)
    local guildId = player:getGuildId()
    if guildId > 0 then
        tools.notifyClientTips(player, "已有盟会")
        return
    end

    local gdata = getGuildData() or {}
    local guildList = gdata.guildList or {}

    local list = {}
    for k, v in pairs(guildList) do
        local lv = v.level
        local cfg = guildLevelConfig[lv]
        if v.needLv == 0 and (cfg and v.cnt < cfg.numMax) then
            table.insert(list, k)
        end    
    end

    if next(list) == nil then
        tools.notifyClientTips(player, "无符合条件的盟会")
        return
    end

    local spid = tostring(pid)

    local otherData = getOtherData() or {}

    local curTime = gTools:getNowTime()

    local cdData = otherData.cdData or {}

    local enterCd = cdData[spid]


    if enterCd then
        if curTime < enterCd then 
            tools.notifyClientTips(player, "cd中请等待")
            return
        end

        cdData[spid] = nil
        enterCd = nil

    end


    local idx = math.random(1, #list)
    local sguildId = list[idx]

    local guildData = guildList[sguildId]

    enterGuild(player, spid, sguildId, guildData, guildList, otherData, guildOptDef.join, curTime)

    saveGuildData()
    saveLogData()
    saveOtherData()

    net.sendMsg2Client(player, ProtoDef.ResOnekeyEnterGuild.name, {})
end

local function ReqCreateGuild(player, pid, proto)
    local guildId = player:getGuildId()
    if guildId > 0 then
        print("ReqCreateGuild already have guild", pid, guildId)
        return
    end

    local name, notice = proto.name, proto.notice

    if not tools.fileterName(player, name, "名字非法") then
        return
    end

    if not tools.fileterName(player, name, "公告非法") then
        return
    end

    local lens = string.len(name)
    if lens > guildBasisConfig.guildNameLen then
        print("ReqCreateGuild too long name", pid, name)
        return
    end

    lens = string.len(notice)
    if lens > guildBasisConfig.guildTextLen then
        print("ReqCreateGuild too long notice", pid, notice)
        return
    end

    local gdata = getGuildData() or {}
    local guildCnt = gdata.guildCnt or 0
    if guildCnt >= guildBasisConfig.guildNum then
        tools.notifyClientTips(player, "达到最大盟会数")
        return
    end


    local otherData = getOtherData() or {}

    local spid = tostring(pid)

    local curTime = gTools:getNowTime()

    local cdData = otherData.cdData or {}

    local enterCd = cdData[tostring(pid)]

    if enterCd then
        if curTime < enterCd then 
            tools.notifyClientTips(player, "cd中请等待")
            return
        end

        cdData[spid] = nil
        cdData = 0

    end

    otherData.useName = otherData.useName or {}
    local useName = otherData.useName
    if useName[name] then
        tools.notifyClientTips(player, "名字已被使用")
        return
    end


    local guildFoundconsume = guildBasisConfig.guildFoundconsume
    local cost = {id = guildFoundconsume[2], type = guildFoundconsume[1], count = guildFoundconsume[3]}
    if not bagsystem.checkAndCostItem(player, {cost}) then
        return
    end

    useName[name] = 1

    gdata.guildList = gdata.guildList or {}
    local guildList = gdata.guildList

    

    guildId = gTools:createUniqueId()

    local sguildId = tostring(guildId)
    gdata.guildCnt = guildCnt + 1

    local info =
    {
        name = name,
        level = 1,
        notice = notice,
        icon = proto.icon,
        frame = proto.frame,
        preUid = spid,
        needLv = proto.needLv,
        mem = {},
        fUids = {}
    }
    
    guildList[sguildId] = info

    enterGuild(player, spid, sguildId, info, guildList, otherData, guildOptDef.create, curTime)

    saveGuildData()
    --saveLogData()
    saveOtherData()

end

local function sendApplyJoinGuild(player, sguildId, code, needLv)
    net.sendMsg2Client(player, ProtoDef.ResApplyJoinGuild.name, {guildId=sguildId, code = code, needLv = needLv})
end

local function ReqApplyJoinGuild(player, pid, proto)
    local sguildId = proto.guildId
    local guildId = player:getGuildId()
    if guildId > 0 then
        print("ReqApplyJoinGuild already have guild", pid, guildId)
        sendApplyJoinGuild(player, sguildId, guildApplyDef.haveGuild)
        return
    end
    
    local gdata = getGuildData() or {}
    local guildList = gdata.guildList or {}

    local spid = tostring(pid)


    local guildData = guildList[sguildId]
    if not guildData then
        print("ReqApplyJoinGuild not find guild", pid, sguildId)
        sendApplyJoinGuild(player, sguildId, guildApplyDef.noFindGuild, 0)
        return
    end

    local needLv = guildData.needLv or 0

    local level = guildData.level
    local cfg = guildLevelConfig[level]
    if not cfg then
        print("ReqApplyJoinGuild no cfg", pid, sguildId, level)
        sendApplyJoinGuild(player, sguildId, guildApplyDef.noFindCfg, needLv)
        return
    end

    local cnt = guildData.cnt or 0
    if cnt >= cfg.numMax then
        print("ReqApplyJoinGuild full", pid, sguildId, level)
        sendApplyJoinGuild(player, sguildId, guildApplyDef.full, needLv)
        return
    end

    local applyCnt = guildData.applyCnt or 0
    if applyCnt >= guildBasisConfig.guildEffectiveNum then
        print("ReqApplyJoinGuild full apply", pid, sguildId, level)
        sendApplyJoinGuild(player, sguildId, guildApplyDef.fullApply, needLv)
        return
    end


    if needLv == -1 then
        print("ReqApplyJoinGuild not apply", pid, sguildId)
        sendApplyJoinGuild(player, sguildId, guildApplyDef.noApply, needLv)
        return
    end

    local myLv = player:getLevel()
    if needLv > 0 and myLv < needLv then
        print("ReqApplyJoinGuild no enough level", pid, sguildId)
        sendApplyJoinGuild(player, sguildId, guildApplyDef.noEnoughLv, needLv)
        return
    end


    guildData.applys = guildData.applys or {}
    local applys = guildData.applys

    if applys[spid] then
        print("ReqApplyJoinGuild already apply", pid, sguildId)
        sendApplyJoinGuild(player, sguildId, guildApplyDef.apply, needLv)
        return
    end

    local otherData = getOtherData() or {}

    local curTime = gTools:getNowTime()

    local cdData = otherData.cdData or {}

    local enterCd = cdData[spid]

    if enterCd then
        if curTime < enterCd then 
            print("ReqApplyJoinGuild cd", pid, sguildId)
            sendApplyJoinGuild(player, sguildId, guildApplyDef.cding, needLv)
            return
        end

        cdData[spid] = nil
        enterCd = 0
    end

    if needLv == 0 then
        enterGuild(player, spid, sguildId, guildData, guildList, otherData, guildOptDef.join, curTime)

        saveLogData()
    else
        local endTime = curTime + guildBasisConfig.guildEffectiveTime

        applys[spid] = endTime
        guildData.applyCnt = applyCnt + 1
    
    
        otherData.applys = otherData.applys or {}
        local applyList = otherData.applys
    
        applyList[spid] = applyList[spid] or {}
        local plist = applyList[spid]
        plist[sguildId] = endTime

        local fUids = tools.clone(guildData.fUids or {})
        table.insert(fUids, guildData.preUid)

        for k, v in pairs(fUids) do
            local nowPlayer = gPlayerMgr:getPlayerById(tonumber(v))
            if nowPlayer then   
                local baseInfo = playersystem.getPlayerBaseInfo(v)
                net.sendMsg2Client(nowPlayer, ProtoDef.NotifyAddNewApplyGuild.name, baseInfo)
            end
        end
    end


    saveGuildData() 
    saveOtherData()

    sendApplyJoinGuild(player, sguildId, guildApplyDef.none, needLv)
end

local function ReqAgreeOrRefuseEnterGuild(player, pid, proto)
    local guildId = player:getGuildId()
    if guildId <= 0 then
        print("ReqAgreeOrRefuseEnterGuild not in guild", pid)
        return
    end

    local sguildId = tostring(guildId)
    local gdata = getGuildData() or {}
    local guildList = gdata.guildList or {}
    local guildData = guildList[sguildId]

    if not guildData then
        print("ReqAgreeOrRefuseEnterGuild not find guild", pid)
        return
    end

    local spid = tostring(pid)
    if spid ~= guildData.preUid and not tools.isInArr(guildData.fUids, spid) then
        print("ReqAgreeOrRefuseEnterGuild no authority", pid)
        return
    end


    local applyPid = proto.pid
    local opt = proto.opt

    
    local otherData = getOtherData() or {}

    if opt == define.agreeOrRefuseStatus.refuse then
        cleanGuildApply(guildData, {[applyPid]=1}, otherData.applys, sguildId)
    else
        local baseInfo = playersystem.getPlayerBaseInfo(applyPid)
        if baseInfo.guildId > 0 then
            tools.notifyClientTips(player, "该玩家已有盟会")
            return
        end

        local cnt = guildData.cnt or 0
        local level = guildData.level
        local cfg = guildLevelConfig[level]
        if not cfg then
            print("ReqAgreeOrRefuseEnterGuild no cfg", pid, sguildId, level)
            return
        end
    
        if cnt >= cfg.numMax then
            print("ReqAgreeOrRefuseEnterGuild full", pid, sguildId, level)
            return
        end

        local curTime = gTools:getNowTime()
        local applyPlayer = gPlayerMgr:getPlayerById(tonumber(applyPid))
        enterGuild(applyPlayer, applyPid, sguildId, guildData, guildList, otherData, guildOptDef.join, curTime)

        saveLogData()
    end



    saveGuildData()
    saveOtherData()

end

local function ReqRefuseAllApplyGuild(player, pid, proto)
    local guildId = player:getGuildId()
    if guildId <= 0 then
        print("ReqRefuseAllApplyGuild not in guild", pid)
        return
    end

    local sguildId = tostring(guildId)
    local gdata = getGuildData() or {}
    local guildList = gdata.guildList or {}
    local guildData = guildList[sguildId]

    if not guildData then
        print("ReqRefuseAllApplyGuild not find guild", pid)
        return
    end

    local spid = tostring(pid)
    if spid ~= guildData.preUid and not tools.isInArr(guildData.fUids, spid) then
        print("ReqRefuseAllApplyGuild no authority", pid)
        return
    end

    local otherData = getOtherData() or {}

    cleanGuildApply(guildData, guildData.applys or {}, otherData.applys, sguildId)


    saveGuildData()
    saveOtherData()
end

local function quitGuild(name, spid, guildList, guildData, sguildId, useName, opt, share, enterCd)  
    enterCd = enterCd or 0

    local cnt = guildData.cnt or 0
    cnt = cnt - 1

    local memList = guildData.mem

    local guildName = guildData.name

    share = share or {}
    share[spid] = nil


    for k, v in pairs(memList) do
        local player = gPlayerMgr:getPlayerById(tonumber(k))
        if player then
            net.sendMsg2Client(player, ProtoDef.NotifyQuitGuild.name, {pid = spid, enterCd = enterCd})
        end
    end

    memList[spid] = nil

    local pid = tonumber(spid)

    local baseInfo = playersystem.getPlayerBaseInfo(pid)
    playersystem.updatePlayerBaseInfo(pid, {guildId = 0}, baseInfo)

    tools.sendOfflinePlayerInfo2Master(pid, baseInfo)

    local player = gPlayerMgr:getPlayerById(pid)
    local kickName = baseInfo.name
    if player then
        player:setGuildId(0)
    else
        local up = {{guildid = 0}}
        local str = tools.encode(up)
        gPlayerMgr:updatePlayerBaseInfo(pid, str)

    end 

    local logData = getLogData() or {}    

    if cnt <= 0 then
        guildList[sguildId] = nil
        logData[sguildId] = nil
        useName[guildName] = nil

        chatinterfacesystem.cleanGuildChatData(sguildId)
    else
        guildData.cnt = cnt

        local logMsg = {logs = {}}
        local title = ""
        local content = ""
        local guildName = guildData.name

        if opt == guildOptDef.kick then
            addLog(sguildId, logData, logMsg.logs, opt, {name, kickName})
            local guildMail2 = guildBasisConfig.guildMail2

            title = guildMail2[1]
            content = string.format(guildMail2[2], guildName)

            mailsystem.sendMail(pid, nil, nil, title, content)
        else
            addLog(sguildId, logData, logMsg.logs, opt, {kickName})
            local guildMail1 = guildBasisConfig.guildMail1

            title = guildMail1[1]
            content = string.format(guildMail1[2], guildName)

            mailsystem.sendMail(pid, nil, nil, title, content)
        end



        notifyAllMemberAddLogs(memList, logMsg)
    end


end

local function ReqKickMember(player, pid, proto)
    local guildId = player:getGuildId()
    if guildId <= 0 then
        print("ReqKickMember not in guild", pid)
        return
    end

    local sguildId = tostring(guildId)
    local gdata = getGuildData() or {}
    local guildList = gdata.guildList or {}
    local guildData = guildList[sguildId]

    if not guildData then
        print("ReqKickMember not find guild", pid)
        return
    end

    local spid = tostring(pid)
    local preUid = guildData.preUid
    local fUids = guildData.fUids

    if spid ~= preUid and not tools.isInArr(fUids, spid) then
        print("ReqKickMember no authority", pid)
        return
    end

    local kickPid = proto.pid
    local memList = guildData.mem
    if not memList[kickPid] then
        print("ReqKickMember not in guild", pid, kickPid)
        return
    end

    if spid == kickPid then
        print("ReqKickMember can not kick self", pid, kickPid)
        return
    end

    local idx = tools.getItemIndex(fUids, kickPid)

    if spid == preUid then
        if idx > 0 then
            table.remove(fUids, idx)
        end
    else
        if kickPid == preUid then
            print("ReqKickMember can not kick president", pid, kickPid)
            return
        end

        if idx > 0 then
            print("ReqKickMember can not kick fpresident", pid, kickPid)
        end
    end


    local otherData = getOtherData() or {}
    local useName = otherData.useName or {}

    local name = player:getName()
    quitGuild(name, kickPid, guildList, guildData, sguildId, useName, guildOptDef.kick, otherData.share)  

    saveGuildData()
    saveLogData()
    saveOtherData()
end

local function getMemList(memList, preUid, curTime, share, list, inheritLeaderMinTime)
    for spid, _ in pairs(memList) do
        if spid ~= preUid then
            local maxScore = share[spid] or 0
            local info = playersystem.getPlayerBaseInfo(spid)
            local mlogoutTime = info.logoutTime or 0
            local interval = curTime - mlogoutTime
            if mlogoutTime == 0 or interval < inheritLeaderMinTime then
                table.insert(list, {pid = spid, score = maxScore, name = info.name, time = mlogoutTime})
            end
        end
    end
end

local function compareByScore(a, b)
    local score1 = a.score
    local score2 = b.score
    if score1 == score2 then
        local time1 = a.time
        local time2 = b.time

        -- 当time1为0时，a应该排在b前面
        if time1 == 0 and time2 ~= 0 then
            return true
        elseif time2 == 0 and time1 ~= 0 then
            return false
        else
            return time1 < time2 -- 如果都不为0，按时间排序
        end
    end

    return score1 > score2
end

local function processProQuit(cdData, preUid, cdTime, list, memList, share, logData, curTime, title, content, useName, guildCnt, guildList, optType, name, guildData, sguildId)
    cdData[preUid] = cdTime

    if not next(list) then
        for spid, _ in pairs(memList) do   
            share[spid] = nil
            local pid = tonumber(spid)

            local baseInfo = playersystem.getPlayerBaseInfo(spid)

            playersystem.updatePlayerBaseInfo(pid, {guildId = 0}, baseInfo)

            tools.sendOfflinePlayerInfo2Master(pid, baseInfo)

            local player = gPlayerMgr:getPlayerById(pid)
            if player then
                player:setGuildId(0)
            else
                local up = {{guildid = 0}}
                local str = tools.encode(up)
                gPlayerMgr:updatePlayerBaseInfo(pid, str)
            end

        end

        logData[sguildId] = nil

        useName[guildData.name] = nil

        chatinterfacesystem.cleanGuildChatData(sguildId)

        guildCnt = guildCnt - 1

        guildList[sguildId] = nil

    else
        table.sort(list, compareByScore)

        --tools.ss(list)

        local idxData = list[1]
        local nowPreUid = idxData.pid
        local optName = idxData.name

        local fUids = guildData.fUids
        local idx = tools.getItemIndex(fUids, nowPreUid)
        if idx > 0 then 
            table.remove(fUids, idx)
        end

        guildData.preUid = nowPreUid


        if optType == guildOptDef.abdicatePresident then
            share[preUid] = nil

            guildData.cnt = guildData.cnt - 1

            local nowPid = tonumber(preUid)

            local baseInfo = playersystem.getPlayerBaseInfo(nowPid)
            playersystem.updatePlayerBaseInfo(nowPid, {guildId = 0}, baseInfo)
        
            tools.sendOfflinePlayerInfo2Master(nowPid, baseInfo)

            local player = gPlayerMgr:getPlayerById(nowPid)

            if player then
                player:setGuildId(0)
            else
                local up = {{guildid = 0}}
                local str = tools.encode(up)
                gPlayerMgr:updatePlayerBaseInfo(nowPid, str)
            end 

            local logMsg = {logs = {}}

            addLog(sguildId, logData, logMsg.logs, guildOptDef.quit, {name})

            notifyAllMemberAddLogs(memList, logMsg)

            logMsg = {logs = {}}

            addLog(sguildId, logData, logMsg.logs, optType, {name, optName})

            notifyAllMemberAddLogs(memList, logMsg)
        else

            local logMsg = {logs = {}}
            addLog(sguildId, logData, logMsg.logs, optType, {name, optName})

            notifyAllMemberAddLogs(memList, logMsg)
        end


        notifyGuildJobUpdate(memList, nowPreUid, fUids, false, preUid)

        content = string.format(content, optName)
        for memId, _ in pairs(memList) do
            mailsystem.sendMail(tonumber(memId), nil, curTime, title, content)
        end
        
    end

    return guildCnt
end

local function ReqQuitGuild(player, pid, proto)
    local guildId = player:getGuildId()
    if guildId <= 0 then
        print("ReqQuitGuild not in guild", pid)
        return
    end

    local sguildId = tostring(guildId)
    local gdata = getGuildData() or {}
    local guildList = gdata.guildList or {}
    local guildData = guildList[sguildId]

    if not guildData then
        print("ReqQuitGuild not find guild", pid)
        return
    end

    local spid = tostring(pid)

    local preUid = guildData.preUid

    local curTime = gTools:getNowTime()

    local otherData = getOtherData() or {}

    local logData = getLogData() or {}

    otherData.cdData = otherData.cdData or {}

    local cdData = otherData.cdData

    local share = otherData.share or {}


    if preUid == spid then
        local inheritLeaderMinTime = guildBasisConfig.inheritLeaderMinTime
        local cdTime = guildBasisConfig.guildPenaltyTime + curTime

        local list = {}
        local curTime = curTime
        local memList = guildData.mem

        local guildMail3 = guildBasisConfig.guildMail3
        local title = guildMail3[1]
        local content = guildMail3[2]

        local useName = otherData.useName

        local guildCnt = gdata.guildCnt or 0

        local preUid = guildData.preUid
        local baseInfo = playersystem.getPlayerBaseInfo(preUid)
        local name = baseInfo.name

        getMemList(memList, preUid, curTime, share, list, inheritLeaderMinTime)

        guildCnt = processProQuit(cdData, preUid, cdTime, list, memList, share, logData, curTime, title, content, useName, guildCnt, guildList, guildOptDef.abdicatePresident, name, guildData, sguildId)

        local smsg = {pid = spid, enterCd = cdTime}
        for k, v in pairs(memList) do
            local player = gPlayerMgr:getPlayerById(tonumber(k))
            if player then
                net.sendMsg2Client(player, ProtoDef.NotifyQuitGuild.name, smsg)
            end
        end

        if next(list) then
            local guildMail1 = guildBasisConfig.guildMail1
            title = guildMail1[1]
            content = string.format(guildMail1[2], guildData.name)

            mailsystem.sendMail(pid, nil, nil, title, content)

            memList[spid] = nil
        end

        gdata.guildCnt = guildCnt
    else
        local fUids = guildData.fUids
        local idx = tools.getItemIndex(fUids, spid)
        if idx > 0 then
            table.remove(fUids, idx)
        end
    
    
        local endTime = curTime + guildBasisConfig.guildPenaltyTime
        cdData[spid] = endTime
    
        local useName = otherData.useName or {}
    
        quitGuild(nil, spid, guildList, guildData, sguildId, useName, guildOptDef.quit, otherData.share, endTime)  
    
    end
    
    saveGuildData()
    saveLogData()
    saveOtherData()
end

local function ReqPromotePresident(player, pid, proto)    
    local guildId = player:getGuildId()
    if guildId <= 0 then
        print("ReqPromotePresident not in guild", pid)
        return  
    end

    local sguildId = tostring(guildId)
    local gdata = getGuildData() or {}
    local guildList = gdata.guildList or {}
    local guildData = guildList[sguildId]

    if not guildData then
        print("ReqPromotePresident not find guild", pid)
        return
    end

    local spid = tostring(pid)
    if spid ~= guildData.preUid and not tools.isInArr(guildData.fUids, spid) then
        print("ReqPromotePresident no authority", pid)
        return
    end


    local jobCnt = guildData.jobCnt or 0
    if jobCnt >= guildBasisConfig.guildFunctionEditNum then
        print("ReqPromotePresident max cnt", pid, jobCnt)
        return
    end

    local opt = proto.opt
    local optPid = proto.pid

    local logMsg = {logs = {}}
    local logData = getLogData() or {}

    local name = player:getName()
    local baseInfo = playersystem.getPlayerBaseInfo(optPid)
    local optName = baseInfo.name

    local params = {name, optName}

    local fUids = guildData.fUids
    local optType = guildOptDef.abdicatePresident
    local preUid = guildData.preUid


    if opt == guildJobChangeDef.president then
        if guildData.preUid == optPid then
            print("ReqPromotePresident yet president", pid)
            return
        end
    
        local idx = tools.getItemIndex(fUids, optPid)
        if idx > 0 then 
            table.remove(fUids, idx)
        end

        guildData.preUid = optPid
        preUid = optPid

    elseif opt == guildJobChangeDef.upPresident then
        if #fUids >= guildBasisConfig.guildFunctionNum[2] then
            print("ReqPromotePresident max cnt", pid)
            return
        end

        if tools.isInArr(fUids, optPid) then
            print("ReqPromotePresident already in fUids", pid)
            return
        end

        table.insert(fUids, optPid)
        optType = guildOptDef.promotePresident
    elseif opt == guildJobChangeDef.dispresident then
        local idx = tools.getItemIndex(fUids, optPid)
        if idx <= 0 then
            print("ReqPromotePresident not in fUids", pid)
            return
        end

        table.remove(fUids, idx)
        optType = guildOptDef.freePresident
    else
        print("ReqPromotePresident opt error", pid, opt)
    end
    
    guildData.jobCnt = jobCnt + 1

    local memList = guildData.mem

    addLog(sguildId, logData, logMsg.logs, optType, params)
    notifyAllMemberAddLogs(memList, logMsg)

    notifyGuildJobUpdate(memList, preUid, fUids, true, spid)

    saveGuildData()
    saveLogData()

end

local function ReqSetJoinNeedLv(player, pid, proto)
    local guildId = player:getGuildId()    
    if guildId <= 0 then
        print("ReqSetJoinNeedLv not in guild", pid)
        return
    end

    local sguildId = tostring(guildId)
    local gdata = getGuildData() or {}
    local guildList = gdata.guildList or {}
    local guildData = guildList[sguildId]

    if not guildData then
        print("ReqSetJoinNeedLv not find guild", pid)
        return
    end

    local spid = tostring(pid)
    if spid ~= guildData.preUid and not tools.isInArr(guildData.fUids, spid) then
        print("ReqSetJoinNeedLv no authority", pid)
        return
    end

    local needLv = proto.needLv
    guildData.needLv = needLv

    for k, v in pairs(guildData.mem) do
        local nowPlayer = gPlayerMgr:getPlayerById(tonumber(k))
        if nowPlayer then
            net.sendMsg2Client(nowPlayer, ProtoDef.NotifyGuildNeedLvUpdate.name, {needLv = needLv})
        end 

    end

    saveGuildData()

end

local function ReqChangeGuildNotice(player, pid, proto)
    local guildId = player:getGuildId()    
    if guildId <= 0 then
        print("ReqChangeGuildNotice not in guild", pid)
        return
    end

    local sguildId = tostring(guildId)
    local gdata = getGuildData() or {}
    local guildList = gdata.guildList or {}
    local guildData = guildList[sguildId]

    if not guildData then
        print("ReqChangeGuildNotice not find guild", pid)
        return
    end

    local spid = tostring(pid)
    if spid ~= guildData.preUid and not tools.isInArr(guildData.fUids, spid) then
        print("ReqChangeGuildNotice no authority", pid)
        return
    end

    local noticeCnt = guildData.noticeCnt or 0
    if noticeCnt >= guildBasisConfig.guildTextNum then
        print("ReqChangeGuildNotice max cnt", pid)
        return
    end

    local notice = proto.notice
    if not tools.fileterName(player, notice, "公告非法") then
        return
    end

    if string.len(notice) > guildBasisConfig.guildTextLen then
        print("ReqChangeGuildNotice too long notice", pid, notice)
        return
    end

    guildData.notice = notice
    guildData.noticeCnt = noticeCnt + 1

    -- local logData = getLogData() or {}
    -- local logMsg = {logs = {}}

    -- local name = player:getName()
    -- addLog(sguildId, logData, logMsg.logs, guildOptDef.changeNotice, {name})

    saveGuildData()
    --saveLogData()

    for k, v in pairs(guildData.mem) do
        local nowPlayer = gPlayerMgr:getPlayerById(tonumber(k))
        if nowPlayer then
            net.sendMsg2Client(nowPlayer, ProtoDef.NotifyGuildNoticeUpdate.name, {notice = notice})   
        end
    end

    --notifyAllMemberAddLogs(guildData.mem, logMsg)
end

local function ReqChangeGuildName(player, pid, proto)
    local guildId = player:getGuildId()    
    if guildId <= 0 then
        print("ReqChangeGuildName not in guild", pid)
        return
    end

    local sguildId = tostring(guildId)
    local gdata = getGuildData() or {}
    local guildList = gdata.guildList or {}
    local guildData = guildList[sguildId]

    if not guildData then
        print("ReqChangeGuildName not find guild", pid)
        return
    end

    local spid = tostring(pid)
    if spid ~= guildData.preUid and not tools.isInArr(guildData.fUids, spid) then
        print("ReqChangeGuildName no authority", pid)
        return
    end

    local nameCnt = guildData.nameCnt or 0
    if nameCnt >= guildBasisConfig.guildNameNum then
        print("ReqChangeGuildName max cnt", pid)
        return
    end

    local name = proto.name
    if not tools.fileterName(player, name, "名字非法") then
        return
    end

    if string.len(name) > guildBasisConfig.guildNameLen then
        print("ReqChangeGuildName too long name", pid, name)
        return
    end

    local oldName = guildData.name
    if name ~= oldName then
        local otherData = getOtherData() or {}
        otherData.useName = otherData.useName or {}
        local useName = otherData.useName
        if useName[name] then
            tools.notifyClientTips(player, "名字已被使用")
            return
        end
    
        useName[name] = 1
        useName[oldName] = nil
    end



    local icon = proto.icon
    local frame = proto.frame

    guildData.name = name
    guildData.icon = icon
    guildData.frame = frame
    guildData.nameCnt = nameCnt + 1

    -- local logData = getLogData() or {}
    -- local logMsg = {logs = {}}

    -- local pname = player:getName()
    -- addLog(sguildId, logData, logMsg.logs, guildOptDef.changeName, {pname})

    saveGuildData()
    saveOtherData()
    --saveLogData()

    for k, v in pairs(guildData.mem) do
        local nowPlayer = gPlayerMgr:getPlayerById(tonumber(k))
        if nowPlayer then
            net.sendMsg2Client(nowPlayer, ProtoDef.NotifyGuildNameUpdate.name, {name = name, icon = icon, frame = frame})   
        end
    end

    --notifyAllMemberAddLogs(guildData.mem, logMsg)
end


local function notifyMemberLoginOrLogout(player, pid, opt)
    local spid = tostring(pid)

    local guildId = player:getGuildId()
    if guildId <= 0 then
        return
    end

    local sguildId = tostring(guildId)
    local gdata = getGuildData() or {}
    local guildList = gdata.guildList or {}
    local guildData = guildList[sguildId] or {}
    for k, v in pairs(guildData.mem or {}) do
        if k ~= spid then
            local nowPlayer = gPlayerMgr:getPlayerById(tonumber(k))
            if nowPlayer then
                net.sendMsg2Client(nowPlayer, ProtoDef.NotifyMemberLoginOrLogout.name, {pid = pid, opt = opt})  
            end
        end
    end
    
end

local function new4Day()
    local gdata = getGuildData() or {}
    local guildList = gdata.guildList or {}
    local msgs = {}
    for k, v in pairs(guildList) do
        local guildData = guildList[k]
        guildData.nameCnt = nil
        guildData.noticeCnt = nil
        guildData.jobCnt = nil

        for k, v in pairs(guildData.mem) do
            local nowPlayer = gPlayerMgr:getPlayerById(tonumber(k))
            if nowPlayer then
                net.sendMsg2Client(nowPlayer, ProtoDef.NotifyGuildNewDay.name, msgs)
            end
        end
    end

    saveGuildData()
end

local function login(player, pid, curTime, isfirst)
    notifyMemberLoginOrLogout(player, pid, guildMemberLoginOrLogoutDef.login)
end

local function logout(player, pid, curTime)
    notifyMemberLoginOrLogout(player, pid, guildMemberLoginOrLogoutDef.logout)
end



local function serverMinute(curTime, playerList)
    local guildData = getGuildData() or {}
    local leaderOfflineTime = guildBasisConfig.leaderOfflineTime
    local inheritLeaderMinTime = guildBasisConfig.inheritLeaderMinTime
    local cdTime = guildBasisConfig.guildPenaltyTime + curTime
    local guildMail3 = guildBasisConfig.guildMail3
    local title = guildMail3[1]
    local content = guildMail3[2]
    
    local logData = getLogData() or {}

    local otherData = getOtherData() or {}

    local share = otherData.share or {}

    otherData.cdData = otherData.cdData or {}

    local cdData = otherData.cdData

    local optType = guildOptDef.offlineAbdicatePresident

    local useName = otherData.useName

    local ok = false
    local guildList = guildData.guildList or {}

    local guildCnt = guildData.guildCnt or 0

    for k, v in pairs(guildList) do
        local preUid = v.preUid
        local baseInfo = playersystem.getPlayerBaseInfo(preUid)
        local name = baseInfo.name

        local logoutTime = baseInfo.logoutTime or 0
        local list = nil
        local memList = v.mem
        if logoutTime > 0 and curTime - logoutTime > leaderOfflineTime then
            list = {}
            ok = true

            getMemList(memList, preUid, curTime, share, list, inheritLeaderMinTime)
        end

        if list then
            --tools.ss(list)
            guildCnt = processProQuit(cdData, preUid, cdTime, list, memList, share, logData, curTime, title, content, useName, guildCnt, guildList, optType, name, v, k)
        end
    end

    if ok then  
        guildData.guildCnt = guildCnt

        saveGuildData()
        saveOtherData()
        saveLogData()
    end


end

local function gmCleanGuildData(player, pid, args)
    local gdata = getGuildData() or {}
    tools.cleanTableData(gdata)
    local otherData = getOtherData() or {}
    tools.cleanTableData(otherData)
    local logData = getLogData() or {}
    tools.cleanTableData(logData)
    saveGuildData()
    saveOtherData()
    saveLogData()
end

local function gmCleanGuildByIdData(player, pid, args)
    local gdata = getGuildData() or {}
    local id = "72106347516808"
    gdata.guildList[id] = nil
    saveGuildData()
end

local function gmShowGuildData(player, pid, args)
    local gdata = getGuildData() or {}
    local guildList = gdata.guildList or {}
    tools.ss(gdata)
end

local function gmShowOtherData(player, pid, args)
    local otherData = getOtherData() or {}
    tools.ss(otherData)
end

local function gmShowLogData(player, pid, args)
    local logData = getLogData() or {}
    tools.ss(logData)
end


local function gmReqCreateGuild(player, pid, args)
    pid = 72106282604621
    player = gPlayerMgr:getPlayerById(pid)
    player:setGuildId(0)
    ReqCreateGuild(player, pid, {name = "宏未28", icon = 11, frame = 11, notice = "宏未"})
end

local function gmReqGuildListInfo(player, pid, args)
    pid = 72105847067163
    player = gPlayerMgr:getPlayerById(pid)
    ReqGuildListInfo(player, pid, {name = "test", icon = 11, frame = 11, notice = "test"})
end

local function gmReqGuildInfo(player, pid, args)
    pid = 72105909236828
    player = gPlayerMgr:getPlayerById(pid)
    ReqGuildInfo(player, pid, {name = "test", icon = 11, frame = 11, notice = "test"})
end

local function gmReqGuildApplyList(player, pid, args)
    pid = 72105847010695
    player = gPlayerMgr:getPlayerById(pid)
    ReqGuildApplyList(player, pid, {name = "test", icon = 11, frame = 11, notice = "test"})
end

local function gmReqApplyJoinGuild(player, pid, args)
    pid = 72106262734720
    player = gPlayerMgr:getPlayerById(pid)
    player:setGuildId(0)
    ReqApplyJoinGuild(player, pid, {guildId="72106264162748"})
end

local function gmReqOnekeyEnterGuild(player, pid, args)
    pid = 72105847067163
    player = gPlayerMgr:getPlayerById(pid)
    player:setGuildId(0)
    ReqOnekeyEnterGuild(player, pid)
end

local function gmReqAgreeOrRefuseEnterGuild(player, pid, args)
    local opt = 0
    local pid = 72105909236828
    player = gPlayerMgr:getPlayerById(pid)
    ReqAgreeOrRefuseEnterGuild(player, pid, {pid = "72106088288652", opt = opt})
end

local function gmReqRefuseAllApplyGuild(player, pid, args)
    local pid = 72105847010695
    player = gPlayerMgr:getPlayerById(72105847010695)
    ReqRefuseAllApplyGuild(player, pid)
end

local function gmReqGuildLogInfo(player, pid, args)
    local pid = 72105847010695
    player = gPlayerMgr:getPlayerById(72105847010695)
    ReqGuildLogInfo(player, pid)
end

local function gmReqKickMember(player, pid, args)
    local pid = 72105847010695
    player = gPlayerMgr:getPlayerById(72105847010695)
    ReqKickMember(player, pid, {pid = "72105847067163"})
end

local function gmReqPromotePresident(player, pid, args)
    local pid = 72105847010695
    player = gPlayerMgr:getPlayerById(72105847010695)
    ReqPromotePresident(player, pid, {pid = "72105847067163",opt=1})
end

local function gmReqChangeGuildNotice(player, pid, args)
    local pid = 72105847010695
    player = gPlayerMgr:getPlayerById(72105847010695)
    ReqChangeGuildNotice(player, pid, {notice = "牛奶"})
end

local function gmReqChangeGuildName(player, pid, args)
    local pid = 72105847010695
    player = gPlayerMgr:getPlayerById(72105847010695)
    ReqChangeGuildName(player, pid, {name = "牛奶", icon = 11, frame = 11})
end

gm.reg("gmCleanGuildByIdData", gmCleanGuildByIdData)
gm.reg("gmCleanGuildData", gmCleanGuildData)
gm.reg("gmShowGuildData", gmShowGuildData)
gm.reg("gmShowOtherData", gmShowOtherData)
gm.reg("gmShowLogData", gmShowLogData)
gm.reg("gmReqCreateGuild", gmReqCreateGuild)
gm.reg("gmReqGuildListInfo", gmReqGuildListInfo)
gm.reg("gmReqGuildInfo", gmReqGuildInfo)
gm.reg("gmReqGuildApplyList", gmReqGuildApplyList)
gm.reg("gmReqApplyJoinGuild", gmReqApplyJoinGuild)
gm.reg("gmReqOnekeyEnterGuild", gmReqOnekeyEnterGuild)
gm.reg("gmReqAgreeOrRefuseEnterGuild", gmReqAgreeOrRefuseEnterGuild)
gm.reg("gmReqRefuseAllApplyGuild", gmReqRefuseAllApplyGuild)
gm.reg("gmReqGuildLogInfo", gmReqGuildLogInfo)
gm.reg("gmReqKickMember", gmReqKickMember)
gm.reg("gmReqPromotePresident", gmReqPromotePresident)
gm.reg("gmReqChangeGuildNotice", gmReqChangeGuildNotice)
gm.reg("gmReqChangeGuildName", gmReqChangeGuildName)

event.reg(event.eventType.new4Day, new4Day)
event.reg(event.eventType.login, login)
event.reg(event.eventType.logout, logout)
event.reg(event.eventType.serverMinute, serverMinute)

net.regMessage(ProtoDef.ReqGuildListInfo.id, ReqGuildListInfo, net.messType.gate)
net.regMessage(ProtoDef.ReqGuildInfo.id, ReqGuildInfo, net.messType.gate)
net.regMessage(ProtoDef.ReqGuildApplyList.id, ReqGuildApplyList, net.messType.gate)
net.regMessage(ProtoDef.ReqGuildLogInfo.id, ReqGuildLogInfo, net.messType.gate)

net.regMessage(ProtoDef.ReqOnekeyEnterGuild.id, ReqOnekeyEnterGuild, net.messType.gate)
net.regMessage(ProtoDef.ReqCreateGuild.id, ReqCreateGuild, net.messType.gate)
net.regMessage(ProtoDef.ReqApplyJoinGuild.id, ReqApplyJoinGuild, net.messType.gate)
net.regMessage(ProtoDef.ReqAgreeOrRefuseEnterGuild.id, ReqAgreeOrRefuseEnterGuild, net.messType.gate)
net.regMessage(ProtoDef.ReqRefuseAllApplyGuild.id, ReqRefuseAllApplyGuild, net.messType.gate)
net.regMessage(ProtoDef.ReqKickMember.id, ReqKickMember, net.messType.gate)
net.regMessage(ProtoDef.ReqPromotePresident.id, ReqPromotePresident, net.messType.gate)
net.regMessage(ProtoDef.ReqSetJoinNeedLv.id, ReqSetJoinNeedLv, net.messType.gate)
net.regMessage(ProtoDef.ReqChangeGuildName.id, ReqChangeGuildName, net.messType.gate)
net.regMessage(ProtoDef.ReqChangeGuildNotice.id, ReqChangeGuildNotice, net.messType.gate)
net.regMessage(ProtoDef.ReqQuitGuild.id, ReqQuitGuild, net.messType.gate)
