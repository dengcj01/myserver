

heroMgr = {}

local function getData(player)
    return playerModuleDataMgr.getData(player, PlayerModuleDefine.hero)
end

local function saveData(player)
    playerModuleDataMgr.saveData(player, PlayerModuleDefine.hero)
end



function heroMgr.getAnNewHero(player, itemId)
    local datas = getData(player)
    if not datas then
        print("getAnNewHero err", itemId)
        return
    end

    local uid = gTools:createUniqueId()
    local suid = tostring(uid)
    datas.list = datas.list or {}
    local list = datas.list

    local info = 
    {
        level = 1,
        star = 0,
        step = 0,
        skin = 0,
        id = itemId,
        power = 0
    }    


    list[suid] = info

    return uid, info
end

function heroMgr.packHeroData(uid, heroData)
    heroData = heroData or {}
    local info =
    {
        uid = uid,
        level = heroData.level or 1,
        star = heroData.star or 0,
        step = heroData.step or 0,
        power = heroData.power or 0,
        skin = heroData.skin or 0,
        id = heroData.heroId,
    }

    return info
end


local function ReqHeroList(player, pid, proto)
    local datas = getData(player)
    if not datas then
        print("ReqHeroList err", pid)
        return
    end

    local msgs = {data = {}}
    local data = msgs.data
    for k, v in pairs(datas.list or {}) do
        table.insert(data, heroMgr.packHeroData(tonumber(k), v))
    end

    sendMsg2Client(player, ProtoDef.ResHeroList.name, msgs)
end







netMgr.regMessage(ProtoDef.ReqHeroList.id, ReqHeroList, netMgr.messType.gate)
