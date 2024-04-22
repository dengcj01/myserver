


local function getData(player)
    return playerModuleDataMgr.getData(player, PlayerModuleDefine.formation)
end

local function saveData(player)
    playerModuleDataMgr.saveData(player, PlayerModuleDefine.formation)
end
