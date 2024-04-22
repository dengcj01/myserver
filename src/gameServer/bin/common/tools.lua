
toolsMgr = {}

local json = require "cjson"



function toolsMgr.luaGc(curTime)
	local gcTime = math.random(301, 420)
	--local gcTime = math.random(3, 3)

	toolsMgr.time = toolsMgr.time or curTime + gcTime
	if curTime >= toolsMgr.time then
		toolsMgr.time = curTime + gcTime
		collectgarbage("collect")
		--print("-------------lua gc")
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
		-- 这里进行一次深拷贝
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
				if pass and "_G" ~= k then
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



function toolsMgr.ss(t, desc)
	--print(debug.traceback("----from this where"))
	print(changeTab(t, desc))
end


function toolsMgr.split(str, delimiter)
	-- 默认以空格为分隔符
	delimiter = delimiter or ' '
	if delimiter == '' then
		return {str}
	end

	local pos,arr = 0, {}

	for st,sp in function() return string.find(str, delimiter, pos, true) end do
		table.insert(arr, string.sub(str, pos, st - 1))
		pos = sp + 1
	end
	table.insert(arr, string.sub(str, pos))

	return arr
end

function toolsMgr.megerReward(rewardList)
	rewardList = rewardList or {}

	local tmp = {}
	for k, v in pairs(rewardList) do
		tmp[v.id] = (tmp[v.id] or 0) + v.count
	end

	return tmp
end

function toolsMgr.getOpenServerDay(curTime)
	local zeroTime = gTools:get0Time(curTime or os.time())
	return math.floor(math.abs(__oepnServerTime - zeroTime) / 86400) + 1
end

function toolsMgr.isArr(tab)
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
	local isarr = toolsMgr.isArr(tab)
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



function toolsMgr.encode(arr)
	if type(arr) ~= "table" then
		print("toolsMgr.encode err")
		return "{}"
	end

	local tab = convertKeysToStrings(arr)
	local res = toolsMgr.safeCall(json.encode, tab)
	if res then
		return res
	end

	print("toolsMgr.encode err")

	return "{}"
end

function toolsMgr.decode(str)
	if type(str) ~= "string" or string.len(str) == 0 then
		print("toolsMgr.decode warn", str)
		return {}
	end

	return toolsMgr.safeCall(json.decode, str)
end

local function errFunc(err)
    print(tostring(err))
    print(debug.traceback())
end

function toolsMgr.safeCall(func, ...)
    local args = table.pack(...)
    local function onfunc()
        return func(table.unpack(args))
    end
    local _, res = xpcall(onfunc, errFunc)
	return res
end

function toolsMgr.cleanTableData(tab)
	if type(tab) ~= "table" then
		return
	end

	for k, v in pairs(tab) do
		tab[k] = nil
	end
end

function toolsMgr.getFilterRes(tab)
	for k, v in pairs(tab) do
		return k, v
	end
end

function toolsMgr.changeRewardArr2Map(tab)
	local ret = {}
    for k, v in pairs(tab) do
        ret[v.id] = (ret[v.id] or 0) + v.count
    end
	return ret
end

function toolsMgr.clone(tab)
	if type(tab) ~= "table" then
		return {}
	end

    local ret = {}
    for k, v in pairs(tab) do
        if type(v) == "table" then
			ret[k] = toolsMgr.clone(v)
		else
			ret[k] = v
		end
    end

    return ret
end


function toolsMgr.mergeRewardArr(arr1, arr2)
	for k, v in pairs(arr2 or {}) do
		table.insert(arr1, v)
	end
end
