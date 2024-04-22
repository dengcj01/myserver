

local tmp = {}

local function load()
    for k, v in pairs(stditems) do
        if tmp[k] then
            print("------------- exist repeated item", k)
        end

        local str = toolsMgr.encode(v)
        gCfgMgr:loadItem(str)
        tmp[k] = 1
    end

end

--laod()

tmp = nil