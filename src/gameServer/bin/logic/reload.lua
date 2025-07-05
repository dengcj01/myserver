




for k, v in pairs(_G.cacheLuaModule) do
    package.loaded[k] = nil
    _G.cacheLuaModule[k] = nil
end



package.loaded["logic.main"] = nil


require("logic.main")


print("-------------------------热更新完毕-------------------------")