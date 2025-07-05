local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"
local systemConfig = require "logic.config.system"
local playermoduledata = require "common.playermoduledata"
local playersystem = require "logic.system.playersystem"
local bagsystem = require "logic.system.bagsystem"
local globalmoduledata = require "common.globalmoduledata"

local mailsystem = {}

local function getGlobalData()
    return globalmoduledata.getGlobalData(define.globalModuleDefine.mail)
end

local function saveGlobalData()
    globalmoduledata.saveGlobalData(define.globalModuleDefine.mail)
end



local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.mail)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.mail)
end

-- 单个邮件操作定义
local mailOptDef = 
{
    read = 1, -- 读
    recv = 2, -- 领取
    del = 3 -- 删除
}

-- 一键邮件操作定义
local oneKeyMailOptDef = {
    recv = 1, -- 领取
    del = 2 -- 删除
}

-- 默认发送邮件人的名字



local systemConfig0 = systemConfig[0]
local defaultMailSendName = systemConfig0.emailName

local defaultMailMaxLimit = systemConfig0.mailNumb -- 邮件默认数量
local defaultMailExpireTime = systemConfig0.mailTime -- 邮件默认过期时间



function mailsystem.getDefaultMailExpireTime()
    return defaultMailExpireTime
end

local function addMail(player, sendName, sendTime, title, content, reward, desc, expireTime, extra, notice)
    local pid = player:getPid()
    local datas = getData(player)
    if not datas then
        print("newMail err", pid)
        return
    end

    if notice == nil then
        notice = true
    end

    local id = gTools:createUniqueId()
    datas.mails = datas.mails or {}
    local mails = datas.mails

    local len = #mails
    if len >= defaultMailMaxLimit then
        local first = mails[1]
        local msg = {id = first.id, opt = mailOptDef.del}
        table.remove(mails, 1)

        net.sendMsg2Client(player, ProtoDef.ResOptMail.name, msg)
    end

    local info = 
    {
        title = title,
        content = content,
        expireTime = expireTime,
        rd = reward,
        extra = extra,
        id = tostring(id),
        sendName = sendName,
        sendTime = sendTime
    }
    table.insert(mails, info)

    saveData(player)



    if notice then
        local msgs = {data = {}}
        table.insert(msgs.data, info)

        net.sendMsg2Client(player, ProtoDef.NotifyAddNewMail.name, msgs)

        --tools.ss(msgs)
    end
end

function mailsystem.addPlayerMail(player, sendName, sendTime, title, content, reward, desc, expireTime, extra, notice)
    addMail(player, sendName, sendTime, title, content, reward, desc, expireTime, extra, notice)
end



local function ReqMailList(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqMailList no datas", pid)
        return
    end

    local msgs = {data={}}
    local data = msgs.data
    local dels = {}
    local curTime = gTools:getNowTime()
    for k, v in pairs(datas.mails or {}) do
        local id = v.id
        local expireTime = v.expireTime
        if curTime >= expireTime then
            table.insert(dels, id)
        else
            local info = {
                id = id,
                title = v.title,
                content = v.content,
                status = v.status or 0,
                expireTime = v.expireTime,
                rd = v.rd or {},
                sendTime = v.sendTime,
                sendName = v.sendName
            }
    
            table.insert(data, info)
        end
    end

    if next(dels) then
        for k, v in pairs(dels) do
            for idx, mdata in pairs(data) do
                if mdata.id == v then
                    table.remove(mdata, idx)
                    break
                end
            end
        end
        saveData(player)
    end

    --tools.ss(msgs)
    net.sendMsg2Client(player, ProtoDef.ResMailList.name, msgs)
end

local function ReqOptMail(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqOptMail no datas", pid)
        return
    end

    local mails = datas.mails
    if not mails then
        print("ReqOptMail no mails", pid)
        return
    end

    local opt = proto.opt or 0
    if opt < mailOptDef.read or opt > mailOptDef.del then
        print("ReqOptMail opt err", pid, opt)
        return
    end

    local id = proto.id

    local data = nil
    local idx = nil
    local del = nil
    local curTime = gTools:getNowTime()
    for k, v in pairs(mails) do
        if v.id == id then
            data = v
            idx = k
            if curTime >= v.expireTime then
                del = true
            end
            break
        end
    end

    if not data then
        print("ReqOptMail no data", pid)
        return
    end

    if del then
        print("ReqOptMail expireTime", pid)
        return
    end


    if opt == mailOptDef.recv or opt == mailOptDef.read then
        local status = data.status or 0

        if opt == mailOptDef.recv then
            local rd = data.rd
            if not rd or next(rd) == nil then
                print("ReqOptMail no rd", pid, id, opt)
                return
            end

            bagsystem.addItems(player, rd)

            data.rd = nil
        else
            if status ~= 0 then
                print("ReqOptMail yet read", pid, id, status)
                return
            end
        end

        data.status = opt

    elseif opt == mailOptDef.del then
        if data.rd and next(data.rd) then
            print("ReqOptMail have rd", pid, id, opt)
            return
        end

        table.remove(mails, idx)
        --addMailLog(player, id, data, "删除邮件")
    end


    saveData(player)

    local msgs = {}
    msgs.id = id
    msgs.opt = opt

    net.sendMsg2Client(player, ProtoDef.ResOptMail.name, msgs)
end

local function ReqOneKeyOptMail(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqOneKeyOptMail no datas", pid)
        return
    end

    local opt = proto.opt or 0
    if opt < oneKeyMailOptDef.recv or opt > oneKeyMailOptDef.del then
        print("ReqOneKeyOptMail opt err", pid, opt)
        return
    end

    local mails = datas.mails
    if not mails then
        print("ReqOneKeyOptMail no mails", pid)
        return
    end

    local msgs = {
        data = {},
        opt = opt
    }


    local rds = {}
    local del = {}
    local curTime = gTools:getNowTime()

    if opt == oneKeyMailOptDef.recv then
        for k, v in pairs(mails) do
            local rd = v.rd
            local id = v.id
            if rd and next(rd) and curTime < v.expireTime then
                tools.mergeRewardArr(rds, rd)
                v.status = mailOptDef.recv
                v.rd = nil
                table.insert(msgs.data, id)
            end
        end

        if next(rds) then
            bagsystem.addItems(player, rds)
        end
    else
        for k, v in pairs(mails) do
            local rd = v.rd
            local id = v.id
            if not rd or next(rd) == nil then
                table.insert(msgs.data, id)
                table.insert(del, id)
            end
        end
    end

    for _, v in pairs(del) do
        for k, vv in pairs(mails) do
            if vv.id == v then
                table.remove(mails, k)
                break
            end
        end
    end

    saveData(player)

    if next(msgs.data) then
        net.sendMsg2Client(player, ProtoDef.ResOneKeyOptMail.name, msgs)
    end
    

end

local function addOfflineMailData(globalData, pid, sendName, sendTime, title, content, reward, desc, expireTime, extra)
    -- 离线玩家保存数据
    globalData = globalData or getGlobalData()

    local spid = tostring(pid)
    globalData[spid] = globalData[spid] or {}
    local mdata = globalData[spid]

    local cnt = #mdata
    if cnt >= 30 then
        table.remove(mdata, 1)
    end

    table.insert(mdata, {
        title = title,
        content = content,
        rd = reward,
        extra = extra,
        expireTime = expireTime,
        sendName = sendName,
        sendTime = sendTime
    })

end

-- 发发邮件统一对外接口
function mailsystem.sendMail(pid, sendName, sendTime, title, content, reward, desc, expireTime, extra)
    title = title or "gm"
    content = content or "gm"
    desc = desc or "gm"
    reward = reward or {}
    extra = extra or {}
    local curTime = gTools:getNowTime()
    expireTime = expireTime or (curTime +  defaultMailExpireTime)

    sendName = sendName or defaultMailSendName
    sendTime = sendTime or curTime

    if gParseConfig:isMasterServer() then
        local info = playersystem.getPlayerBaseInfo(pid)
        if not info then
            print("mailsystem.sendMail no info", pid)
        else
            local msgs = {}
            msgs.title = title
            msgs.content = content
            msgs.expireTime = expireTime
            msgs.rd = reward
            msgs.desc = desc
            msgs.extra = tools.encode(extra)
            msgs.sendName = sendName
            msgs.sendTime = sendTime
            msgs.pid = pid

            net.sendMsg2Game(info.serverId, ProtoDef.ReqMasterSendMail.name, msgs)
        end
    else
        local player = gPlayerMgr:getPlayerById(pid)
        if player then
            addMail(player, sendName, sendTime, title, content, reward, desc, expireTime, extra)
        else
            addOfflineMailData(nil, pid, sendName, sendTime, title, content, reward, desc, expireTime, extra)
            saveGlobalData()
        end
    end


end


local function login(player, pid, curTime, isfirst)
    local globalData = getGlobalData() or {}
    local spid = tostring(pid)
    local data = globalData[spid]
    if not data then
        return
    end


    local datas = getData(player) or {}
    local cnt = #datas
    local ok = false
    for i = cnt, 1, -1 do
        local mdata = datas[i]
        if mdata and curTime >= mdata.expireTime then
            table.remove(datas, i)
            ok = true
        end
    end


    for k, v in pairs(data) do
        local expireTime = v.expireTime
        if curTime < expireTime then
            addMail(player, v.sendName, v.sendTime, v.title, v.content, v.rd, v.desc, expireTime, v.extra, false)
        end
    end

    globalData[spid] = nil
    saveGlobalData()

    if ok then
        saveData(player)
    end
end


local function addHttpMail(data)
    local expireTime = gTools:getNowTime() + defaultMailExpireTime
    local title = data.title
    local content = data.content
    local rd = {}
    for k, v in pairs(data.attachments or {}) do
        local key = v.key
        local ret = tools.splitByNumber(key, "-")
        if #ret <= 1 then
            print("addHttpMail err")
            return
        end
        table.insert(rd, {id = ret[1], type = ret[2], count = tonumber(v.value)})
    end


    local extra = {}
    if data.unique_id then
        extra.uniqueId = tonumber(data.unique_id)
    end

    local desc = data.desc or "后台添加邮件"
    local nowTime = gTools:getNowTime()


    if data.type == 1 then -- 个人邮件
        for k, v in pairs(data.uids or {}) do
            v = tonumber(v)
            mailsystem.sendMail(v, defaultMailSendName, nowTime, title, content, rd, desc, expireTime, extra)
        end
    else
        local playerList = gPlayerMgr:getOnlinePlayers()
        for k, v in pairs(playerList) do 
            mailsystem.sendMail(k, defaultMailSendName, nowTime, data.title, data.content, rd, desc, expireTime, extra)
        end

        local globalData = getGlobalData()
        for k, v in pairs(_G.allCachePlayers) do
            addOfflineMailData(globalData, k, defaultMailSendName, nowTime, title, content, rd, desc, expireTime, extra)
        end
        saveGlobalData()
    end
end

local function ReqMasterSendMail(srcServerId, proto)
    local pid,title,content,expireTime,rd,sendName,sendTime,desc,extra = proto.pid, proto.title, proto.content, proto.expireTime, proto.rd, proto.sendName, proto.sendTime, proto.desc, proto.extra

    extra = tools.decode(extra)

    mailsystem.sendMail(pid, sendName, sendTime, title, content, rd, desc, expireTime, extra)
end



local function showmail(player, pid, args)
    player = gPlayerMgr:getPlayerById(283205492487570)
    tools.ss(getData(player))

    tools.ss(getGlobalData())
end

local function showmail1(player, pid, args)
    -- player = gPlayerMgr:getPlayerById(283204382464333)
    -- tools.ss(getData(player))
    tools.ss(getGlobalData())
end

local function showmail11(player, pid, args)
    local datas = getGlobalData()
    tools.cleanTableData(datas)
    saveGlobalData()
    player = gPlayerMgr:getPlayerById(283204735615849)
    local datas1 = getData(player)
    tools.cleanTableData(datas1)
    saveData(player)

end


local function optmails(player, pid, args)
    player = gPlayerMgr:getPlayerById(283204735615849)
    --ReqOptMail(player, player:getPid(), {id=283203969988645,opt=3})
    ReqOneKeyOptMail(player, player:getPid(),{opt=1})
end

local function addmail(player, pid, args)
    --player = gPlayerMgr:getPlayerById(283204735615849)
    mailsystem.sendMail(pid, defaultMailSendName, gTools:getNowTime(), "啊啊", "大大", {{id=3201,count=1000,type=1}})
end

local function addmail1(player, pid, args)
    --player = gPlayerMgr:getPlayerById(283204735615849)
    mailsystem.sendMail(pid, defaultMailSendName, gTools:getNowTime(), "test1", "test1")
end



gm.reg("showmail", showmail)
gm.reg("showmail1", showmail1)
gm.reg("showmail11", showmail11)
gm.reg("optmails", optmails)
gm.reg("addmail", addmail)
gm.reg("addmail1", addmail1)

event.reg(event.eventType.login, login)
event.regHttp(event.optType.mail, event.httpEvent[event.optType.mail].addMail, addHttpMail)

net.regMessage(ProtoDef.ReqMailList.id, ReqMailList, net.messType.gate)
net.regMessage(ProtoDef.ReqOptMail.id, ReqOptMail, net.messType.gate)
net.regMessage(ProtoDef.ReqOneKeyOptMail.id, ReqOneKeyOptMail, net.messType.gate)

net.regMessage(ProtoDef.ReqMasterSendMail.id, ReqMasterSendMail, net.messType.game)



return mailsystem
