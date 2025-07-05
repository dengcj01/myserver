

local tools = require "common.tools"
local net = require "common.net"

local md5 = require "common.md5"
local httpsystem = require "logic.system.httpsystem"



local gm = {list = {}}


function gm.reg(funName, func)
    if type(func) ~= "function" or type(funName) ~= "string" then
        printTrace("reg gm no func", func, func)
        return
    end

    gm.list[funName] = func
end





function gm.testsave(player, pid, args)
    gGetGlobalModuleData()

end

function gm.gc(player, pid, args)
    collectgarbage("collect")
end




-- 测试是否是中文,或者普通字符
local function testStr()
    print("xxxxx", tTools:isValidStr("aa"))
    print("xxxxx", tTools:isValidStr("暗法f"))
    print("xxxxx", tTools:isValidStr("漢聽"))
    print("xxxxx", tTools:isValidStr("~"))
    print("xxxxx", tTools:isValidStr("!"))
    print("xxxxx", tTools:isValidStr("`"))
    print("xxxxx", tTools:isValidStr("#"))
    print("xxxxx", tTools:isValidStr("%"))
    print("xxxxx", tTools:isValidStr("*"))
    print("xxxxx", tTools:isValidStr("-"))
    print("xxxxx", tTools:isValidStr("="))
    print("xxxxx", tTools:isValidStr("+"))
    print("xxxxx", tTools:isValidStr("["))
    print("xxxxx", tTools:isValidStr("}"))
    print("xxxxx", tTools:isValidStr("\\"))
    print("xxxxx", tTools:isValidStr("?"))
    print("xxxxx", tTools:isValidStr("▲"))
    print("xxxxx", tTools:isValidStr("｛"))
    print("xxxxx", tTools:isValidStr("⑳"))
    print("xxxxx", tTools:isValidStr("⒎"))
    print("xxxxx", tTools:isValidStr("㏒"))
    print("xxxxx", tTools:isValidStr("⅓"))
    print("xxxxx", tTools:isValidStr("Ξ"))
    print("xxxxx", tTools:isValidStr("æ"))
    print("xxxxx", tTools:isValidStr("┌"))
    print("xxxxx", tTools:isValidStr("╳"))
    print("xxxxx", tTools:isValidStr("β"))
end

-- 测试敏感词
function gm.testFilter()
    local file1 = io.open("logic/config/testname.lua", "r")
    local file2 = io.open("logic/config/res11111111111111111111111111111111.lua", "w")
    if file1 then
        for line in file1:lines() do
            line = line:gsub("\r", "")
            local res = gFilter:filterName(line)
            if string.len(line) > 0 and string.len(res) == 0 then
                file2:write(line .. "\n")
            end
            
        end
        file1:close()
        file2:close()
    end
end


function gm.servertime(player, pid, args)
    print(__nextDayTime, __nextMinTime)
    print(__nextDayTime, __nextMinTime)
end


-- 归还堆内存
function gm.trim(player, pid, args)
    gTools:mallocTrim()
end

function gm.onlinecnt(player, pid, args)
    print(string.format("当前在线人数: %d", gPlayerMgr:getOnlineCnt()))
end

function gm.isonline(player, pid, args) -- isonline 283203954584375
    print("isOnlineisOnline", args[1])
    print(gPlayerMgr:getPlayerById(args[1]))
end


function gm.save(player, pid, args)
    gMainThread:save()
end



local function ReqServerGm(player, pid, proto)
    local cmd = proto.cmd
    local arsg = proto.args
    local args = tools.splitByNumber(arsg)

    local gmLv = player:getGmLevel()
    if gmLv == 0 then
        print("ReqServerGm gmlv == 0", pid)
        return
    end

    local params = {0}
    for i, v in ipairs(args) do
        table.insert(params,(v))
    end
    
    _G.gluaFuncprocessCmd(player, pid, cmd, params)
end



function gm.forceclose(player, pid, args) -- forceclose 72104634635743
    local pid = args[1]
    local reason = args[2] or BackgroundKick
    player = gPlayerMgr:getPlayerById(pid)
    if player then
        gMainThread:forceCloseSession(player:getSessionId(), player:getCsessionId(), reason)
    end
end

function gm.removeAccountByAccount(player, pid, args)
    gMainThread:removeAccountByAccount("WWpiU0trN3R6ekNhNEJ1VXBUTXFLZz09A","nopf",1)
end



function gm.coredump(player, pid, args)
    gMainThread:coreDump()

end

function gm.setentercnt(player, pid, args)
    gMainThread:setEnterCnt(1)

end

function gm.getMessageCnt1(player, pid, args)
    local cnt = gMainThread:getMessageCnt()
    print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxx", cnt)
end


function gm.showOnlinePlayer(player, pid, args)
    local onlinePlayer = gPlayerMgr:getOnlinePlayers()
    for k, v in pairs(onlinePlayer) do
        print(k, v)
    end
    
end

function gm.testhttp(player, pid, args)
    local host = "139.224.236.108"
	local path = "/historyWeather/citys"
    local data =  "province_id=1&key=YOUR_KEY"
    gMainThread:sendMessage2Http(host, path, data)
end

function gm.test(player, pid, args)
    print("test")
end

-- 排行榜测试
function gm.testRank(player, pid, args)
    local rankObj = gRankMgr:getRank("test", 5)
    if rankObj then
        -- rankObj:updateRank(1, 999, 10)
        -- rankObj:updateRank(2, 999, 10)
        -- rankObj:updateRank(3, 900, 10)
        -- rankObj:updateRank(4, 908, 10)

        rankObj:updateRank(1, 999, 10)


        local list = rankObj:getRankItemList()
        for k, v in ipairs(list) do
            local str = string.format("id:%d        v1:%d       v2:%d       v3:%d       time:%s", v:getId(), v:getVal1(), v:getVal2(), v:getVal3(), gTools:getStringTime(v:getTime()))
            print(str)
        end


        gRankMgr:save(rankObj, true)

    end
end

function gm.showrank(player, pid, args)
    local rankObj = gRankMgr:getRank("test", 100)
    if rankObj then
        local list = rankObj:getRankItemList()
        for k, v in ipairs(list) do
            local str = string.format("id:%d        v1:%d       v2:%d       v3:%d       time:%s", v:getId(), v:getVal1(), v:getVal2(), v:getVal3(), gTools:getStringTime(v:getTime()))
            print(str)
        end
    end
end


net.regMessage(ProtoDef.ReqServerGm.id, ReqServerGm, net.messType.gate)

return gm