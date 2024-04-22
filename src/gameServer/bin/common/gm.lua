

local lfs = require("lfs")


gmMgr = {
    gmlist = {}
}

function gmMgr.reg(funName, func)
    if type(func) ~= "function" or type(funName) ~= "string" then
        printTrace("reg gm no func", func, func)
        return
    end

    gmMgr.gmlist[funName] = func
end

local function delConfig(path, tab)
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local filename = file:match("(.+)%..+")
            table.insert(tab, filename)
        end
    end
end

function gmMgr.rsf(player, pid, args)
    for k, v in pairs(cacheLuaModule) do
        if package.loaded[k] then
            package.loaded[k] = nil
            cacheLuaModule[k] = nil
        end
    end


    local tab = {}
    delConfig("logic/config/", tab)
    delConfig("logic/config/zh-cn/", tab)
    for k, v in pairs(tab) do
        _G[v]=nil
    end

    
    collectgarbage("collect")

    require("logic.main")
    package.loaded["logic.main"] = nil


end

function gmMgr.forceLogout(player, pid, args)
    local pid = args[1] or 0
    local reason = args[2] or 1
    player = gPlayerMgr:getPlayerById(pid)
    if player then
        gMainThread:forceCloseSession(player:getSessionId(), player:getCsessionId(), reason)
    end
end

function gmMgr.forceAllLogout(player, pid, args)
    local list = gPlayerMgr:getOnlinePlayers()
    for k, v in pairs(list) do
        gMainThread:forceCloseSession(v:getSessionId())
    end
end

function gmMgr.testsave(player, pid, args)
    toolsMgr.ss(globaModulelDirtryData, "globaModulelDirtryData")
    toolsMgr.ss(globaModulelData, "globaModulelData")
    toolsMgr.ss(playerModeleDataDirtyList, "playerModeleDataDirtyList")
    toolsMgr.ss(playerModeleDataList, "playerModeleDataList")

end

function gmMgr.gc(player, pid, args)
    collectgarbage("collect")
end

function gmMgr.load(player, pid, args)
    gMainThread:testfunc()
end

-- 排行榜测试
local function testRank()
    local rankObj = gRankMgr:initRank("test", 30737412)
    if rankObj then
        rankObj:updateRank(1, 1, 4, 2, 1)
        rankObj:updateRank(2, 1, 4, 2, 1)
        rankObj:updateRank(3, 1, 4, 2, 1)
        rankObj:updateRank(4, 2, 4, 2, 1)
        -- rankObj:delRankItemByRanking(1)

        -- local list = rankObj:getRankList()
        -- print("xaaaaaaa",#list)
        -- for k, v in pairs(list) do
        --     --print(v:getId(),v:getVal1(),v:getVal2(),v:getVal3())
        -- end

        gRankMgr:save(rankObj, true)

        -- gRankMgr:delRank("test")
        -- gRankMgr:cleanRank("test")
        -- rankObj = gRankMgr:initRank("test", 4)
        -- list = rankObj:getRankList()
        -- print("xbbbbbbb",#list)
        -- for k, v in pairs(list) do
        --     print(v:getId(),v:getVal1(),v:getVal2(),v:getVal3())
        -- end

        -- local v = rankObj:getRankItem(10000)
        -- if v then
        --     print(v:getId(),v:getVal1(),v:getVal2(),v:getVal3(),v:getServerId())
        -- end
    end
end

-- 测试tab转成字符串
local function testTab2Str()
    local aa = toolsMgr.encode({{
        a = 1
    }, {
        b = 1
    }})
    print(aa)
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
local function testFilter()
    local file1 = io.open("logic/config/filterword.lua", "r")
    local file2 = io.open("logic/config/res.lua", "w")
    if file1 then
        local cnt = 0
        for line in file1:lines() do
            cnt = cnt + 1
            line = line:gsub("\r", "")
            local res = gFilter:filterWorld(line)
            local strRes = toolsMgr.encode(res)
            file2:write(strRes .. "\n")
        end
        file1:close()
        file2:close()
    end
end

local function testLoad()
    gPlayerMgr:testLoad()
end

local function testTimerFunc(a, b, c, d)
    print(a, b, c, d)
    toolsMgr.ss(d)
end

function gmMgr.test(player, pid, args)
    print(__nextDayTime, __nextMinTime)
    -- testRank()
    -- testLoad()
    -- local gdata = _G.globaModulelDataList
    -- print(gdata)
    -- gMainThread:saveGlobalData()

    -- for k, v in pairs(globaModulelDataList) do
    --     globaModulelDirtryList[k] = 1
    -- end
    -- local player = gPlayerMgr:fakeLogin(1)
    -- local aa = timerMgr.addTimer(player, 3, testTimerFunc, 1, 1,"c",{a=1,b={}})
    -- print(aa)
    -- timerMgr.delTimer(player, aa)

    -- local aa = toolsMgr.decode('"{"enter":1,"sortId":3"name":"积天累充11","config":1,"btnIcon":1,"openGuaJiId":15}"')
    -- print("xxxxx",aa)
    -- local extra = toolsMgr.encode({a=1,b=2})
    -- print(extra)
    -- --local reward = {}
    -- local reward = {{id=1,count=1},{id=2,count=11}}
    -- local aaa = toolsMgr.encode({[1]={mailId=1,desc="aa",extra=toolsMgr.encode({a=1,b=2}),title="title",content="content",expireTime=1,reward=reward},[2]={mailId=1,desc="aa",extra=toolsMgr.encode({a=1,b=2,c={}}),title="title",content="content",expireTime=1,reward=reward}})
    -- print(aaa)
    -- gMainThread:addMailLog(player, aaa)
    -- gRankMgr:initRank("tt", 10)
    -- local rank = gRankMgr:getRank("tt")
end

function gmMgr.test1(player, pid, args)
    -- print(_G.playerModeleDataList)
    -- print("aa")
    -- for pid, v in pairs(playerModeleDataList) do
    --     playerModeleDataDirtyList[pid] = {}
    --     for k, vv in pairs(v) do
    --         playerModeleDataDirtyList[pid][k] = 1
    --     end

    -- end

    -- gPlayerMgr:testSave()
    -- player = gPlayerMgr:fakeLogin(1)
    -- timerMgr.delTimer(player, "3")

    player = gPlayerMgr:getPlayerById(283176258643165)
    --playerMgr.addItem(player, {{id=1,count=1},{id=20101,count=2},{id=20102,count=3}},"test")
    -- print("xxxxxxxxxx", player:getItemCount(1))
    -- print("xxxxxxxxxx1", player:getItemCount(20101))
    -- print("xxxxxxxxxx2", player:getItemCount(20102))

    --print("xxxxxxxxxxxx",playerMgr.checkAndCostItem(player,{{id=1,count=20}}))
    print("xxxxxxxxxxxxx",playerMgr.costItem(player, {{id=20102,count=2}}, "testdel",{opt="test",name="dcj",arr={1,2,3}}))
    --player:removeItemByGuid(283178181581292,"test","")
    --player:removeItemById(20101,"test","")
end

function gmMgr.test2(player, pid, args)
    -- gGetPlayerModuleData(283176258643165)
    --playerMgr.itemEnough(player)
    for i=1,10 do
        print("xxxxxx",gTools:random(1,100))
    end
end

function gmMgr.test3(player, pid, args)

    player = gPlayerMgr:getPlayerById(283176258643165)
    print("xxxxxxxxxx", player:getItemCount(1))
    print("xxxxxxxxxx1", player:getItemCount(20101))
    print("xxxxxxxxxx2", player:getItemCount(20102))
    --toolsMgr.ss(playerModuleDataMgr.getData(player,PlayerModuleDefine.mail))
end

-- 归还堆内存
function gmMgr.trim(player, pid, args)
    gTools:mallocTrim()
end

function gmMgr.onlinecnt(player, pid, args)
    print(string.format("当前在线人数: %d", gPlayerMgr:getOnlineCnt()))
end

function gmMgr.isonline(player, pid, args)
    print("isOnlineisOnline", args[1])
    print(gPlayerMgr:getPlayerById(args[1]))
end

function gmMgr.sendmail(player, pid, args)
    pid = args[1]
    local serverId = args[2] or gParseConfig:getServerId()

    mailMgr.sendMail(pid, serverId, "啊啊", "大大", {{id=1,count=2}}, "天天", 1000, {aa=1,bb=2,rd={{1,3}}})
end

function gmMgr.delmail(player, pid, args)
    local id = args[1]
    player = gPlayerMgr:getPlayerById(283176258643165)
    local mail = playerModuleDataMgr.getData(player, PlayerModuleDefine.mail)
    local data = mail.mails[tostring(id)]

    local info = {
        mailId = id,
        desc = "删除邮件",
        extra = data.extra or {},
        title = data.title,
        content = data.content,
        expireTime = data.time,
        reward = data.rd or {}
    }

    gMainThread:addMailLog(player, toolsMgr.encode(info))

end

local function testtime1(player, tab)
    print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
    toolsMgr.ss(tab)
end

function gmMgr.testtimer(player, pid, args)
    player = gPlayerMgr:getPlayerById(283178732503068)
    toolsMgr.ss(stditems[20101].staticAttrs)
    timerMgr.addTimer(player, 15, testtime1, 0,{a=1,cfg=stditems[20101].staticAttrs})
end

function gmMgr.testclone(player, pid, args)
    local xx = toolsMgr.clone({{id=1},{count=2}})
    toolsMgr.ss(xx)
end

function gmMgr.testfighttask(player, pid, args)
    -- player = gPlayerMgr:getPlayerById(283178732503068)
    -- local t = {a=1,b=2}
    -- local tt = toolsMgr.encode(t)
    -- print("aaaaaaaaaaaaaa",tt)
    -- gFightMgr:test(283178732503068, tt)

    -- local aa= gFightMgr:checkAndPack(0,1)

    -- local cc = toolsMgr.decode(aa)

    -- toolsMgr.ss(cc)



    local t =     
    {
        id=1,
        round=10,
        team1=
        {
            aa=1,
            enList=
            {
                {id=1,skills={1,2},attr={["1"]=2,["5"]=39}},
                {id=2,skills={11,22},attr={["5"]=230,["1"]=3}},
            }
        },
        team2=
        {
            aa=11,
            enList=
            {
                {id=111,skills={133,22},attr={[1]=2,[5]=33}},
                {id=222,skills={11,223},attr={[5]=2023,[1]=3}},
            }    
        }
    }

    for i=1,1 do
        print("xxxxxxxxxx",toolsMgr.encode(t))
        gFightMgr:addRandom(i, toolsMgr.encode(t))

    end
    --gFightMgr:addRandom(1, toolsMgr.encode(t))


end

function gmMgr.testmysql(player, pid, args)
    print("11111111111111111111")
    toolsMgr.ss(args)
end


