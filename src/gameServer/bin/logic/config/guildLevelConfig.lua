--keys:lv|exp|numMax|
local guildLevelConfig={
[1]={lv=1,exp=100,numMax=10,},
[2]={lv=2,exp=300,numMax=15,},
[3]={lv=3,exp=400,numMax=20,},
[4]={lv=4,exp=500,numMax=25,},
[5]={lv=5,exp=600,numMax=30,},
[6]={lv=6,exp=0,numMax=50,},

}

local default_value = {
    exp = 100,
numMax = 10,

}
local setmetatable = setmetatable
local metatable = nil
local function __newindex(t, k, v)
    setmetatable(t, nil)
    t[k] = v
    --NE.LOG_ERROR("请不要修改表格字段!")
    setmetatable(t, metatable)
end
metatable = {__index = default_value, __newindex = __newindex}
for _, v in pairs(guildLevelConfig) do
    setmetatable(v, metatable)
end
 
return guildLevelConfig
