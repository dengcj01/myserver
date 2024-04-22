









_G.cacheFightData = _G.cacheFightData or {}


local function packageEntity(heroData)
    local info = 
    {
        id = heroData.id,
        step = heroData.step or 0,
        star = heroData.star or 0,
        level = heroData.level or 1,
        skin = heroData.skin or 0
    }

    info.skills = {}
    info.attr = {}

    return info
end


local function packPlayerTeam(player, pid)
    local team = {enList = {}}
    team.name = player:getName()
    team.icon = player:getIcon()
    team.headIcon = player:getHeadIcon()
    team.vip = player:getVip()

    local formation = playerModuleDataMgr.getData(player, PlayerModuleDefine.formation)
    if not formation then
        print("packPlayerTeam err1", pid)
        return {}, false
    end

    local heros = playerModuleDataMgr.getData(player, PlayerModuleDefine.hero)
    if not heros then
        print("packPlayerTeam err2", pid)
        return {}, false
    end

    local enList = team.enList
    for k, v in pairs(formation) do
        local heroData = heros[k]
        if not heroData then
            print("packPlayerTeam err3", pid)
            return {}, false
        end

        table.insert(enList, packageEntity(heroData))
    end

    return team, true
end


local function ReqFight(player, pid, proto)
    local type = proto.type
    local p1 = proto.p1 
    local p2 = proto.p2
    local p3 = proto.p3
    local p4 = proto.p4
    local p5 = proto.p5

    local otherTeam = nil



    local nowTime = os.time()
    local msgs = {}
    msgs.p1 = p1
    msgs.p2 = p2
    msgs.p3 = p3
    msgs.p4 = p4
    msgs.p5 = p5
    msgs.type = type
    msgs.round = 10
    msgs.seed = os.time()

    if type == FightTypeDef.checkpoint then
        local ohterStrTeam = gFightMgr:checkAndPack(type, 1)
        if ohterStrTeam == "" then
            return
        end

        otherTeam = toolsMgr.decode(ohterStrTeam)
        msgs.team2 = otherTeam
    end


    local team1, ret = packPlayerTeam(player, pid)
    if not ret then
        return
    end

    msgs.team1 = team1
 
    if type == FightTypeDef.arena then
        local player1 = gPlayerMgr:getPlayerById(p1)
        if not player1 then
            player1 = gPlayerMgr:fakeLogin(p1)
        end    

        otherTeam, ret = packPlayerTeam(player1, p1)
        if not ret then
            return
        end

        msgs.team2 = otherTeam

    end


    local uid = gTools:createUniqueId()
    _G.cacheFightData[uid] = {pid=pid,msgs=msgs,time=nowTime+300}


    gFightMgr:addRandom(uid, toolsMgr.encode(msgs))
end


function gFightEndRes(uid, res)
    local fightData = _G.cacheFightData[uid]
	if not fightData then
		print("gFightEndRes warn",uid)
		return
	end

	local pid = fightData.pid
	local player = gPlayerMgr:getPlayerById(fightData.pid)
	if not player then
    	print("gFightEndRes tip no player", pid)
		_G.cacheFightData[uid]=nil
    	return
	end



    sendMsg2Client(player, ProtoDef.ResFight.name, fightData.msgs)

end

local function update()
 	local nowTime = os.time()
    for k, v in pairs(cacheFightData) do
		if nowTime >= v.time then
			cacheFightData[k]=nil
		end
    end
end

serverEventMgr.reg(ServerEventDefine.serverMinute, update)


netMgr.regMessage(ProtoDef.ReqFight.id, ReqFight, netMgr.messType.gate)
