




-- 禁止使用模块内部直接返回模块,否则热更新不生效

if _G.__init == nil then
	package.cpath = package.cpath ..";../../../libs/?.so;../../../../libs/?.so;../../../libs/socket/?.so;../../../../libs/socket/?.so;../../../libs/mime/?.so;../../../../libs/mime/?.so"


	local openServerTimePath = "logic/opentime.txt"
	local file = io.open(openServerTimePath,"r")
	if not file then
		file = io.open(openServerTimePath,"w")
		file:write(os.date("%Y%m%d"))
		file:close()
		file = io.open(openServerTimePath,"r")
	end

	for line in file:lines() do
		local year = tonumber(string.sub(line, 1,4))
		local month = tonumber(string.sub(line, 5,6))
		local day = tonumber(string.sub(line, 7,8))
		_G.__oepnServerTime = gTools:get0Time(os.time({year = year, month = month, day = day, hour = 0,min = 0, sec = 0})) 
		_G.__nextDayTime = __oepnServerTime + 86400
	end

	file:close()
	_G.__init = ""

	local filterFile = io.open("logic/config/filterword.lua","r")
	if filterFile then
		for line in filterFile:lines() do
			line = line:gsub("\r", "")
			gFilter:add(line)
		end
		gFilter:initFailPoint()
		filterFile:close()
	end
end





require("common.log")
_G.cacheLuaModule = _G.cacheLuaModule or {}


_G.myRequire = function(path, flag)
	require(path)
	if flag ~= true then
		cacheLuaModule[path] = true
	end
end


myRequire("common.tools")






-- 热更新不会生效的文件
myRequire("common.debug", true)


myRequire("logic.config.zh-cn.itemname")



myRequire("logic.config.stditems")
myRequire("logic.config.activities")
myRequire("logic.config.autoOpenActivitiesCfgs")
myRequire("logic.config.Pointconfigs")






myRequire("common.msgdef")
myRequire("common.parseProto")
myRequire("common.event")
myRequire("common.timer")
myRequire("common.gm")
myRequire("common.define")
myRequire("common.net")
myRequire("common.playermodulemgr")
myRequire("common.loadglobaldata")
myRequire("common.playermgr")
myRequire("common.loadstditems")



myRequire("logic.system.activesystem")
myRequire("logic.system.mailsystem")
myRequire("logic.system.herosystem")
myRequire("logic.system.formationsystem")
myRequire("logic.system.fightsystem")









