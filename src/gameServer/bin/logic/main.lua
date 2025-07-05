




package.cpath = package.cpath .. ";../../../libs/?.so;../../../../libs/?.so;../../../libs/socket/?.so;../../../../libs/socket/?.so;../../../libs/mime/?.so;../../../../libs/mime/?.so" 




require("common.log")



--local filterConfig = require("logic.config.filterConfig")

if _G.__init == nil then
	local openServerTimePath = "logic/opentime.txt"
	local file = io.open(openServerTimePath,"r")
	if not file then
		file = io.open(openServerTimePath,"w")
		file:write(gTools:getNowYMD())
		file:close()
		file = io.open(openServerTimePath,"r")
	end

	for line in file:lines() do
		local year = tonumber(string.sub(line, 1,4))
		local month = tonumber(string.sub(line, 5,6))
		local day = tonumber(string.sub(line, 7,8))
		_G.__oepnServerTime = gTools:get0Time(gTools:getNowTimeByDate(year, month, day)) 
		_G.__nextDayTime = gTools:get0Time(gTools:getNowTime()) + 86400 -- 服务器0点
		_G.__nextNewDayTime = __nextDayTime + 14400 -- 玩家凌晨4点
	end

	file:close()
	_G.__init = 0

	local file1 = io.open("logic/config/filterConfig.txt", "r")
    if file1 then
        for line in file1:lines() do
            line = line:gsub("\r", "")
			gFilter:add(line)

            
        end
        file1:close()

    end


    gFilter:initFailPoint()
end



_G.cacheLuaModule = _G.cacheLuaModule or {}


_G.myRequire = _G.myRequire or function(path, flag)
	require(path)

	if flag ~= true then
		cacheLuaModule[path] = 1
	end
end


myRequire("common.tools")



--部分配置优先加载


--热更新不会生效的文件
if not gParseConfig:isDaemon() then
	myRequire("common.debug", true)
end




--热更新会生效的文件
-- 配置表

myRequire("logic.config.system")
myRequire("logic.config.equipAttribute")

myRequire("logic.config.itemConfig")


myRequire("logic.config.hero")

myRequire("logic.config.equip")
myRequire("logic.config.workshop")
myRequire("logic.config.workshopTalent")
myRequire("logic.config.workshopUpgrade")

myRequire("logic.config.fightLevelup")
myRequire("logic.config.skill")

myRequire("logic.config.talent")
myRequire("logic.config.talentBusiness")
myRequire("logic.config.talentNature")
myRequire("logic.config.furniture")
myRequire("logic.config.alchemy")
myRequire("logic.config.drop")


myRequire("logic.config.ratingLevel")
myRequire("logic.config.order_CustomerEquip")
myRequire("logic.config.order_HeroEquip")
myRequire("logic.config.order_Princess")
myRequire("logic.config.order_WorkerMaterial")
myRequire("logic.config.order_WorkerEquip")

myRequire("logic.config.gacha")
myRequire("logic.config.gachaDropConfig")
myRequire("logic.config.ratingLevelUnlock")
myRequire("logic.config.shopConfig")
myRequire("logic.config.furnitureLevelup")

myRequire("logic.config.battlePoint")
myRequire("logic.config.fightHero")

myRequire("logic.config.qualityConfig")
myRequire("logic.config.attribute")
myRequire("logic.config.talentAttribute")
myRequire("logic.config.equipSuit")

myRequire("logic.config.system")
myRequire("logic.config.furnitureTalent")
myRequire("logic.config.equipLevelup")
myRequire("logic.config.storeGoodsConfig")

myRequire("logic.config.storeConfig")
myRequire("logic.config.taskTypeConfig")
myRequire("logic.config.activitytimeConfig")
myRequire("logic.config.taskFunctionConfig")

myRequire("logic.config.activitytimeGMConfig")
myRequire("logic.config.sevenDailyRewardConfig")
myRequire("logic.config.constConfig")
myRequire("logic.config.newGuide")
myRequire("logic.config.functionOpen")
myRequire("logic.config.eightLogRewardConfig")
myRequire("logic.config.order_people")
myRequire("logic.config.towerConfig")
myRequire("logic.config.towerSkillConfig")
myRequire("logic.config.orderSystemConfig")
myRequire("logic.config.orderGroupConfig")
myRequire("logic.config.manageGameplayConfig")
myRequire("logic.config.mailsConfig")

myRequire("logic.config.rechargeConfig")
myRequire("logic.config.equipFormula")
myRequire("logic.config.rechargeGiftConfig")
myRequire("logic.config.cumulativeGiftConfig")
myRequire("logic.config.towerSkillOptionConfig")
myRequire("logic.config.order_WorkerSpecialConfig")
myRequire("logic.config.courseSystemConfig")
myRequire("logic.config.courseLevelupConfig")
myRequire("logic.config.npcConfig")
myRequire("logic.config.npcGiftConfig")
myRequire("logic.config.guildBasisConfig")
myRequire("logic.config.guildLevelConfig")


-- 公共文件
myRequire("common.datadef", true)
myRequire("common.md5", true)
myRequire("common.msgdef", true)
myRequire("common.parseProto", true)
myRequire("common.event")
myRequire("common.timer")
myRequire("common.gm")
myRequire("common.define")
myRequire("common.net")


myRequire("common.playermoduledata")
myRequire("common.globalmoduledata")
myRequire("common.socket.socket", true)
myRequire("common.socket.headers", true)
myRequire("common.socket.ltn12", true)
myRequire("common.socket.mime", true)
myRequire("common.socket.http", true)
myRequire("common.socket.tp", true)
myRequire("common.socket.url", true)

-- 模块文件
myRequire("logic.system.commonsystem")
myRequire("logic.system.httpsystem")
myRequire("logic.system.playersystem")
-- myRequire("logic.system.bagsystem")
-- myRequire("logic.system.mailsystem")
-- myRequire("logic.system.functionopensystem")
-- myRequire("logic.system.chat.chatsystem")
-- myRequire("logic.system.chat.crosschatsystem")
-- myRequire("logic.system.chargesystem")
-- myRequire("logic.system.herosystem")
-- myRequire("logic.system.tasksystem")
-- myRequire("logic.system.guild.guildsystem")

-- 活动系统,运营活动统一放这里
myRequire("logic.system.activity.activitybasesystem")
-- myRequire("logic.system.activity.seventasksystem")
-- myRequire("logic.system.activity.eightsignsystem")
-- myRequire("logic.system.activity.openservermailsystem")

