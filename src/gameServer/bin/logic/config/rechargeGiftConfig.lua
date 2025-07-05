--keys:id|name|lockGift|condition|param|buy|value|reward|sort|kind|
local rechargeGiftConfig={
[1]={id=1,name="首充礼包",lockGift=0,condition={1,2},param={2,35},buy=1,value=8,reward={{20001,20002,20003},{20004,20005},{20006,20007}},sort=1,kind=1,},

}
local empty_table = {}
local default_value = {
    name = "首充礼包",
lockGift = 0,
condition = {1,2},
param = {2,35},
buy = 1,
value = 8,
reward = {{20001,20002,20003},{20004,20005},{20006,20007}},
sort = 1,
kind = 1,

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
for _, v in pairs(rechargeGiftConfig) do
    setmetatable(v, metatable)
end
 
return rechargeGiftConfig
