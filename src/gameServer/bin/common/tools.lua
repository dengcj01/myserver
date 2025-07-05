
local tools = {}

local json = require "cjson"
local md5 = require "common.md5"
local define = require "common.define"
local net = require "common.net"
local equipAttributeCfg = require "logic.config.equipAttribute"
local equipConfig = require "logic.config.equip"

function tools.luaGc(curTime)
	local gcTime = math.random(301, 420)
	--local gcTime = math.random(3, 3)
	tools.time = tools.time or curTime + gcTime
	if curTime >= tools.time then
		tools.time = curTime + gcTime
		collectgarbage("collect")
	end
end

local function tableToSring(...)
	local arg = {...}	
	local t = arg[1]
	if not t then return end
	local tp = type(t)
	if "table" == tp then
		local prefix = arg[2]
		if not prefix then
			prefix = ""
		end

		local minor_prefix = arg[3]
		if not minor_prefix then
			minor_prefix = "    "
		end

		local path = arg[4]
		if not path or "table" ~= type(path) then
			path = {}
		end

		local root = {}
		for k, v in pairs(path) do
			root[k] = v
		end
		table.insert(root, t)
		local indexstr, resultstr = "", prefix.."{".."\n"
		local pass = false
		for k, v in pairs(t) do
			if "string" == type(k) then
				indexstr = string.format("%s[\"%s\"]", prefix..minor_prefix, k)
			elseif "number" == type(k) then
				indexstr = string.format("%s[%d]", prefix..minor_prefix, k)
			end
			local ttp = type(v)
			if "table" == ttp then
				resultstr = resultstr..indexstr.."="
				pass = true
				for key, val in pairs(root) do
					if v == val then
						pass = false
						resultstr = resultstr.."\n"
						break
					end
				end
				if pass then
					local ret = tableToSring(v, prefix..minor_prefix, minor_prefix, root)
					resultstr = resultstr.."\n"..ret
				end
			else
				if "string" == ttp then
					resultstr = resultstr..indexstr.."=".."\""..v.."\""
				elseif "function" == ttp then
					resultstr = resultstr..indexstr.."="..tostring(v)
				elseif "userdata" == ttp then
					resultstr = resultstr..indexstr.."="..tostring(v)
				elseif "number" == ttp then
					local s1 = string.format("%s", tostring(v))
					resultstr = resultstr..indexstr.."="..s1
				elseif "boolean" == ttp then
					resultstr = resultstr..indexstr.."="..string.format("%s", tostring(v))
				end
				resultstr = resultstr..","
				resultstr = resultstr
			end
			resultstr = resultstr.."\n"
		end
		resultstr = resultstr..prefix.."}\n"
		return resultstr
	else
		if "string" == type(t) then
			return "\""..t.."\""
		else
			return tostring(t)
		end
	end
end

local function changeTab(t, desc)
	desc = desc or "table"
	local result
	if "table" == type(t) then
		result=desc.."=\n"
		return result..tableToSring(t)
	else
		return desc
	end
end

local function escape_str(s)
    return s:gsub("\\", "\\\\"):gsub("\"", "\\\"")
end

local function serialize(t, indent, visited)
	indent = indent or 0
    visited = visited or {}
    if type(t) ~= "table" then
        return tostring(t)
    end
    
    if visited[t] then
        return "\"循环引用\""
    end
    visited[t] = true
    
    local spaces = string.rep("    ", indent)
    local inner_spaces = string.rep("    ", indent + 1)
    local lines = {}
    local keys = {}
    
    -- 收集所有键并分类
    for k in pairs(t) do
        table.insert(keys, k)
    end
    
    -- 自定义排序：数字键优先（升序），然后是字符串键（字母序）
    table.sort(keys, function(a, b)
        local ta, tb = type(a), type(b)
        
        if ta == "number" and tb == "number" then
            return a < b
        elseif ta == "number" and tb ~= "number" then
            return true
        elseif ta ~= "number" and tb == "number" then
            return false
        else
            return tostring(a) < tostring(b)
        end
    end)
    
    for _, k in ipairs(keys) do
        local v = t[k]
        local key_str
        
        -- 处理键的格式
        if type(k) == "number" then
            key_str = "[" .. tostring(k) .. "]"
        else
            key_str = "[\"" .. escape_str(tostring(k)) .. "\"]"
        end
        
        -- 处理值的格式
        local value_str
        if type(v) == "table" then
            value_str = serialize(v, indent + 1, visited)
            table.insert(lines, inner_spaces .. key_str .. " = \n" .. value_str)
        else
            if type(v) == "string" then
                value_str = "\"" .. escape_str(v) .. "\""
            elseif type(v) == "number" or type(v) == "boolean" then
                value_str = tostring(v)
            else
                value_str = "\"<" .. type(v) .. ">\""
            end
            table.insert(lines, inner_spaces .. key_str .. " = " .. value_str)
        end
    end
    
    local result = table.concat(lines, ",\n")
    if #lines > 0 then
        return spaces .. "{\n" .. result .. ",\n" .. spaces .. "}"
    else
        return spaces .. "{}"
    end
end

-- 打印函数
function tools.sss(t, desc)
	desc = desc or "当前数据"
    desc = desc .. " =" .. "\n" .. serialize(t)
	print(desc)
end



function tools.ss(t, desc)
	if desc == nil then
		desc = "table"
	end

	desc = tostring(desc)
	--print(debug.traceback("----from this where"))
	local info = debug.getinfo(2) or {}
    
    local txt = string.format("%s [line]=%d:", info.source or "?", info.currentline or 0)
	desc = desc .. txt
	print(changeTab(t, desc))
end

-- 以指定字符分割字符串
function tools.split(str, delimiter)
    -- 默认以空格为分隔符
    delimiter = delimiter or ' '
    if delimiter == '' then
        return {str}
    end

    local pos, arr = 0, {}

    for st, sp in function() return string.find(str, delimiter, pos, true) end do
        -- 插入非空子串
        local substring = string.sub(str, pos, st - 1)
        if substring ~= '' then
            table.insert(arr, substring)
        end
        pos = sp + 1
    end
    
    -- 添加最后一个子串，如果不是空字符串
    local lastSubstring = string.sub(str, pos)
    if lastSubstring ~= '' then
        table.insert(arr, lastSubstring)
    end

    return arr
end

-- 以指定字符分割字符串,内容会转化成数字
function tools.splitByNumber(str, delimiter)
    -- 默认以空格为分隔符
    delimiter = delimiter or ' '
    if delimiter == '' then
        return {str}
    end

    local pos, arr = 0, {}

    for st, sp in function() return string.find(str, delimiter, pos, true) end do
        -- 插入非空子串
        local substring = string.sub(str, pos, st - 1)
        if substring ~= '' then
            table.insert(arr, tonumber(substring))
        end
        pos = sp + 1
    end
    
    -- 添加最后一个子串，如果不是空字符串
    local lastSubstring = string.sub(str, pos)
    if lastSubstring ~= '' then
        table.insert(arr, tonumber(lastSubstring))
    end

    return arr
end

function tools.megerReward(rewardList) -- {type = {id=cnt}}
	rewardList = rewardList or {}

	local tmp = {}
	for k, v in pairs(rewardList) do
		local type = v.type
		tmp[type] = tmp[type] or {}

		local typeData = tmp[type]

		typeData[v.id] = (typeData[v.id] or 0) + v.count
	end

	return tmp
end

function tools.getOpenServerDay(curTime)
	local zeroTime = gTools:get0Time(curTime or gTools:getNowTime())
	return math.floor(math.abs(__oepnServerTime - zeroTime) / 86400) + 1
end

function tools.isArr(tab)
	if type(tab) ~= "table" then
		return false
	end

	local lens = #tab
	local vtype = nil
	for k, v in pairs(tab) do
		if vtype == nil then
			vtype = type(v)
		else
			if vtype ~= type(v) then
				return false
			end
		end

		if type(k) ~= "number" or k > lens then
			return false
		end
	end

	return true
end

local function convertKeysToStrings(tab)
	local tmp = {}
	local isarr = tools.isArr(tab)
	local iter = pairs
	if isarr then
		iter = ipairs
	end

	for k, v in iter(tab) do
		if type(v) == "table" then
			v = convertKeysToStrings(v)
		end

		if isarr then
			table.insert(tmp, v)
		else
			if type(k) ~= "string" then
				k = tostring(k)
			end
			
			tmp[k] = v
		end
	end
	return tmp
end



function tools.encode(arr)
	if type(arr) ~= "table" then
		print("tools.encode err")
		reurn "{}"
	end

	local tab = convertKeysToStrings(arr)
	local ret, res = tools.safeCall(json.encode, tab)
	if ret and res then -- 未出错结果
		return res
	end

	print("tools.encode err", ret, res)

	return "{}" -- 出错给个空tab
end

function tools.decode(str)
	local ret, res = tools.safeCall(json.decode, str)
	if ret and res then
		return res
	end

	print("tools.decode err", ret, res)

	return {} -- 出错给个空tab
end

-- 获取以delimiter分割的最后一个位置的内容
function tools.getLastPart(str, delimiter)
	if type(str) ~= "string" or string.len(str) == 0 or delimiter == nil then
		return nil
	end

    local parts = {}
    for part in string.gmatch(str, "[^" .. delimiter .. "]+") do
        table.insert(parts, part)
    end

	if #parts == 0 then
		return nil
	end

    return parts[#parts]
end

local function errFunc(err)
    print(tostring(err))
    print(debug.traceback())
end

function tools.safeCall(func, ...)
    local args = table.pack(...)
    local function onfunc()
        return func(table.unpack(args))
    end
    local ret, res = xpcall(onfunc, errFunc)
	return ret, res
end

function tools.cleanTableData(tab)
	if type(tab) ~= "table" then
		return
	end

	for k, v in pairs(tab) do
		tab[k] = nil
	end
end

function tools.getFilterRes(tab)
	for k, v in pairs(tab) do
		return k, v
	end
end

function tools.changeRewardArr2Map(tab)
	local ret = {}
    for k, v in pairs(tab) do
        ret[v.id] = (ret[v.id] or 0) + v.count
    end
	return ret
end

function tools.clone(tab)
	if type(tab) ~= "table" then
		return tab
	end

    local ret = {}
    for k, v in pairs(tab) do
        if type(v) == "table" then
			ret[k] = tools.clone(v)
		else
			ret[k] = v
		end
    end

    return ret
end


function tools.mergeRewardArr(arr1, arr2)
	for k, v in pairs(arr2 or {}) do
		table.insert(arr1, v)
	end
end

-- 合并同类型id的奖励
function tools.mergeSameReward(arr)
	local data = tools.megerReward(arr)
	local ret = {}
	for type, v in pairs(data) do
		for id, count in pairs(v) do
			table.insert(ret, {id=id,count=count,type=type})
		end
	end

	return ret
end


-- 合并同id的奖励
function tools.mergeSameIdReward(data, arr)
	for k, v in pairs(arr or {}) do
		local sid = tostring(v.id)
		data[sid] = (data[sid] or 0) + v.count
	end
end


function tools.isInArr(arr, val)
	if type(arr) ~= "table" then
		return false
	end

	for k, v in ipairs(arr) do
		if val == v then
			return true
		end
	end

	return false
end

	-- 遍历数组，查找值 val 的索引
function tools.getItemIndex(arr, val)
	if type(arr) ~= "table" then
		return 0
	end


	for k, v in ipairs(arr) do
		if val == v then
			return k
		end
	end

	return 0
end


-- 格式权重 -- tab = { { 1003, 2833 }, { 1004, 2833 }, { 1005, 2834 }, { 1008, 1500 } }
-- filterList 要被过滤的词条id
-- filterTypeList 要被过滤的词条id类型
function tools.formatWeightTab(tab, filterList, filterTypeList)
	filterList = filterList or {}
	filterTypeList = filterTypeList or {}
	local t = {arr = {}, allWeight = 0}
	local allWeight = 0
	local arr = t.arr
	for k, v in ipairs(tab) do
		local id = v[1]
		local cfg = equipAttributeCfg[id]
		if cfg then
			if not tools.isInArr(filterList, id) and (not tools.isInArr(filterTypeList, cfg.type)) then
				local weight = v[2]
				table.insert(arr, {id = id, weight = weight + allWeight})
				allWeight = weight + allWeight
			end
		else
			print("formatWeightTab err", id)
		end

	end

	t.allWeight = allWeight

	return t
end

-- 格式权重 -- tab = {[123]=1,[111]=21 }
function tools.formatWeightTabByHash(tab)
	local ret = {}
	for k, v in pairs(tab) do
		table.insert(ret, {k, v})
	end
	return ret
end

function tools.baseInfo2Arr(baseInfoList)
	local baseInfo = {}
	for k, v in pairs(baseInfoList or {}) do
		table.insert(baseInfo, v)
	end

	return baseInfo
end

function tools.changeHttp(tab)
	local keys = {}
    for k in pairs(tab) do
        table.insert(keys, k)
    end
    table.sort(keys)
    local sortedTable = {}
    for _, k in ipairs(keys) do
		table.insert(sortedTable,{[k]=tab[k]})
    end
	
	local len = #sortedTable
    local str = {}
    for idx, v in ipairs(sortedTable) do
        for kk, vv in pairs(v) do
            table.insert(str, kk)
            table.insert(str, "=")
            table.insert(str, tostring(vv))
            if idx ~= len then
                table.insert(str, "&")
            end
        end
    end

    local res = table.concat(str)
    --res = res.. "606f46f2b71ca7037a37ef4bdb3941bc"

    local ret = md5.sumhexa(res)
    res = res.."&".."sign".."="..ret

	return res
end


function tools.getCostTime(desc, startTime)
	print("costtime"..desc, (gTools:getClock() - startTime)*1000)
end

function tools.getPlayerNextNewDayTime()
	local curTime = gTools:getNowTime()
	return gTools:get0Time(curTime) + 86400 + 14400
end


function tools.getMinVal(val1, val2)
	if val1 < val2 then
		return val1
	end
	return val2
end

function tools.getMaxVal(val1, val2)
	if val1 > val2 then
		return val1
	end
	return val2
end

function tools.isEven(num)
    return num % 2 == 0
end

function tools.accRdCount(tipRd, id, cnt)
	tipRd[id] = (tipRd[id] or 0) + cnt
end


-- 通知客户端弹框
function tools.notifyClientTips(player, content, tipType)
    if tipType == nil then
        tipType = define.tipsType.defalut
    end

    local msgs = {type = tipType, content = content or ""}
    net.sendMsg2Client(player, ProtoDef.NotifyAddNewTips.name, msgs)
end

-- 通知所有客户端弹框
function tools.notifyAllClientTips(content, tipType)
    if tipType == nil then
        tipType = define.tipsType.defalut
    end

    local msgs = {type = tipType, content = content or ""}

    net.broadcastPlayer(ProtoDef.NotifyAddNewTips.name, msgs)
end

function tools.ranomdQuality(arr, addVal)
	addVal = addVal or 100
	local tmp = tools.clone(arr)
	for k, v in ipairs(tmp) do
		tmp[k] = v * addVal
	end

	local maxWeight = 0
	local ret = {}
	for k, v in ipairs(tmp) do
		local weight = v + maxWeight
		ret[k] = weight
		maxWeight = weight
	end

	local quality = {2, 3, 4, 5}

	local idx = nil
	local val = math.random(1, maxWeight)
	for k, v in ipairs(ret) do
		if val <= v then
			idx = k
			break
		end
	end

	return quality[idx]
end


function tools.getForlumaIdByEquipId(equipId, equipConf)
	equipConf = equipConf or equipConfig
	local conf = equipConf[equipId]
	if conf then
		if conf.stage == define.equipStage.normal then
			local sid = tostring(equipId)
			return sid..0
		else
			return (equipId * 10 + 1)
		end
	end
end

function tools.recoverVal(endTime, curTime, perTime, recover, nowVal, maxVal)
    local leftTime = curTime - endTime + perTime
    local cnt = math.floor(leftTime / perTime) * recover
    
	local nowCnt = cnt + nowVal
	if maxVal == nil then
		maxVal = nowCnt + 1
	end

    if nowCnt < maxVal then
        endTime = endTime + cnt * perTime
    else
        endTime = nil
        nowCnt = maxVal
    end

    local addCnt = nowCnt - nowVal
	return addCnt, endTime
end

function tools.fileterName(player, name, tips)
	local res = gFilter:filterName(name)
    local len = string.len(res)
	tips = tips or "名字非法"
    if len == 0 then

        tools.notifyClientTips(player, tips)
        return
    end

	return true
end


return tools