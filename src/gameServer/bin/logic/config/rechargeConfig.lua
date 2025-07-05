--keys:id|value|reward|firstAward|normalAward|type|
local rechargeConfig={
[1]={id=1,value=6,reward=60,firstAward=60,normalAward=0,type=1,},
[2]={id=2,value=30,reward=300,firstAward=300,normalAward=0,type=1,},
[3]={id=3,value=68,reward=680,firstAward=680,normalAward=40,type=1,},
[4]={id=4,value=98,reward=980,firstAward=980,normalAward=80,type=1,},
[5]={id=5,value=198,reward=1980,firstAward=1980,normalAward=200,type=1,},
[6]={id=6,value=328,reward=3280,firstAward=3280,normalAward=500,type=1,},
[7]={id=7,value=648,reward=6480,firstAward=6480,normalAward=1200,type=1,},
[8]={id=8,value=6,reward=0,firstAward=0,normalAward=0,type=2,},

}

local default_value = {
    value = 6,
reward = 60,
firstAward = 60,
normalAward = 0,
type = 1,

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
for _, v in pairs(rechargeConfig) do
    setmetatable(v, metatable)
end
 
return rechargeConfig
