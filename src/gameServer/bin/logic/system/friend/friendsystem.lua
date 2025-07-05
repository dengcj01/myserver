
local tools = require "common.tools"
local event = require "common.event"
local gm = require "common.gm"
local define = require "common.define"
local net = require "common.net"
local playermoduledata = require "common.playermoduledata"



local function getData(player)
    return playermoduledata.getData(player, define.playerModuleDefine.friend)
end

local function saveData(player)
    playermoduledata.saveData(player, define.playerModuleDefine.friend)
end

local friendsystem = {}








return friendsystem