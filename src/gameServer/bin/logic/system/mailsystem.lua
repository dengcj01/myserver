mailMgr = {}

local defaultMailExpireTime = 30 * 86400

local function getData(player)
    return playerModuleDataMgr.getData(player, PlayerModuleDefine.mail)
end

local function saveData(player)
    playerModuleDataMgr.saveData(player, PlayerModuleDefine.mail)
end

local function getGlobalData()
    return globalModuleDataMgr.getGlobalData(GlobalModuleDefine.mail)
end

local function saveGlobalData()
    return globalModuleDataMgr.saveGlobalData(GlobalModuleDefine.mail)
end

-- 单个邮件操作定义
local mailOptDef = {
    read = 1, -- 读
    recv = 2, -- 领取
    del = 3 -- 删除
}

-- 一键邮件操作定义
local oneKeyMailOptDef =
{
	recv=1, -- 领取
	del=2, -- 删除
}

local function addMailLog(player, id, data, desc)
	local info = 
	{
		mailId = id,
		desc = desc,
		extra = data.extra or {},
		title = data.title,
		content = data.content,
		expireTime = data.time,
		reward = data.rd or {}
	}

	gMainThread:addMailLog(player, toolsMgr.encode(info))
end

local function ReqMailList(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqMailList no datas", pid)
        return
    end

    local msgs = {
        data = {}
    }
    local data = msgs.data
    for k, v in pairs(datas.mails or {}) do
        local info = 
		{
            id = tonumber(k),
            title = v.title,
            content = v.content,
            status = v.status or 0,
            time = v.time,
            data = {}
        }
        for _, rd in pairs(v.rd or {}) do
            table.insert(info.data, {
                id = v.id,
                cnt = v.count
            })
        end
        table.insert(data, info)
    end

    sendMsg2Client(player, ProtoDef.ReqMailList.name, msgs)
end

local function ReqOptMail(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqOptMail no datas", pid)
        return
    end

    local opt = proto.opt or 0
    if opt < mailOptDef.read or opt > mailOptDef.del then
        print("ReqOptMail opt err", pid, opt)
        return
    end

    local id = proto.id
    local sid = tostring(id)
    local mails = datas.mails
    if not mails then
        print("ReqOptMail no mails", pid)
        return
    end

    local data = mails[sid]
    if not data then
        print("ReqOptMail no data", pid)
        return
    end

    local status = data.status or 0
    if status ~= 0 then
        print("ReqOptMail opted", pid, id, status)
        return
    end

    if opt == mailOptDef.recv then
        local rd = data.rd
        if not rd or next(rd) == nil then
            print("ReqOptMail no rd", pid, id, opt)
            return
        end
		data.rd = nil

        playerMgr.addItem(player, rd, RewardLogDefine.recvMail, {id})
	elseif opt == mailOptDef.del then
		if data.rd and next(data.rd) then
    		print("ReqOptMail have rd", pid, id, opt)
			return
		end
		addMailLog(player, id, data, "删除邮件")
    end

    data.status = opt
    saveData(player)

    local msgs = {}
    msgs.id = id
    msgs.status = opt

    sendMsg2Client(player, ProtoDef.ReqOptMail.name, msgs)
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

	local msgs = {data = {}}
	msgs.opt = opt

    local rds = {}

	if opt == oneKeyMailOptDef.recv then
		for k, v in pairs(mails) do
			local rd = v.rd
			if rd and next(rd) then
				toolsMgr.mergeRewardArr(rds, v.rd or {})
				v.status = mailOptDef.recv
				table.insert(msgs.data, tonumber(k))
			end 
		end
	else
		local del = {}
		for k, v in pairs(mails) do
			if not v.rd or next(v.rd) == nil then
				mails[k] = nil
				local nid = tonumber(k)
				table.insert(msgs.data, nid)
				addMailLog(player, nid, v, "删除邮件")
			end
		end
	end

    if next(rds) then
        playerMgr.addItem(player, rds, RewardLogDefine.recvMail, toolsMgr.clone(msgs.data))
    end

	saveData(player)

	sendMsg2Client(player, ProtoDef.ReqOneKeyOptMail.name, msgs)

end

function addMail(player, title, content, reward, desc, expireTime, extra)
	local pid = player:getPid()
	local datas = getData(player)
	if not datas then
		print("newMail err", pid)
		return
	end

	local id = gTools:createUniqueId()
	datas.mails = datas.mails or {}
	local mails = datas.mails
	local sid = tostring(id)
	mails[sid] = 
	{
		title = title,
		content = content,
		time = expireTime,
		rd = reward,
		extra = extra
	}
	saveData(player)

	addMailLog(player, id, mails[sid], desc)

end

function mailMgr.sendMail(pid, serverId, title, content, reward, logDesc, expireTime, extra)
    if not toolsMgr.isArr(reward) then
        print("sendMail err", pid)
        return
    end

    title = title or "gm"
    content = content or "gm"
    logDesc = logDesc or "gm"
    reward = reward or {}
    extra = extra or {}
    expireTime = os.time() + (expireTime or defaultMailExpireTime)

    if gParseConfig:isMasterServer() then
        local msgs = 
        {
            id = gTools:createUniqueId(),
            title = title,
            content = content,
            time = expireTime,
            desc = logDesc,
            data = reward,
            pid = pid,
            extra = toolsMgr.encode(extra),
        }

        sendMsg2Game(serverId, ProtoDef.ResSendMail.name, msgs)
        return
    end


    local player = gPlayerMgr:getPlayerById(pid)
    if player then
        addMail(player, title, content, reward, logDesc, expireTime, extra)
    else
        local globalData = getGlobalData()
        if globalData then
            local spid = tostring(pid)
            globalData[spid] = globalData[spid] or {}

            local data = globalData[spid]

            table.insert(data, {
                title = title,
                content = content,
                time = expireTime,
                rd = reward,
                extra = extra
            })
            saveGlobalData()
        end
    end
end

local function ResSendMail(sourceId, msgs)
    toolsMgr.ss(msgs)
    mailMgr.sendMail(msgs.pid, gParseConfig:getServerId(), msgs.title, msgs.content, msgs.data, msgs.desc, msgs.time, toolsMgr.decode(msgs.extra))
end

local function login(player, isfirst, curTime, isNewDay)
    local globalData = getGlobalData() or {}

	local spid = tostring(player:getPid())
	local data = globalData[spid]
	if not data then
		return
	end


	for k, v in pairs(data) do
		local expireTime = v.time
		if curTime < expireTime then
			addMail(player, v.title, v.content, expireTime, v.rd, v.extra)
		end
	end

	globalData[spid] = nil
	saveGlobalData()

end



serverEventMgr.reg(ServerEventDefine.login, login)

netMgr.regMessage(ProtoDef.ReqMailList.id, ReqMailList, netMgr.messType.gate)
netMgr.regMessage(ProtoDef.ReqOptMail.id, ReqOptMail, netMgr.messType.gate)
netMgr.regMessage(ProtoDef.ReqOneKeyOptMail.id, ReqOneKeyOptMail, netMgr.messType.gate)

netMgr.regMessage(ProtoDef.ResSendMail.id, ResSendMail, netMgr.messType.game)
