




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





