--keys:id|name|lockGift|condition|param|value|type|reward|sort|kind|
local cumulativeGiftConfig={
[1]={id=1,name="累充礼包第一档",lockGift=0,condition={1,2},param={2,45},value=30,type=1,reward={21004,21005,21006},sort=1,kind=1,},
[2]={id=2,name="累充礼包第二档",lockGift=0,condition={1,2},param={2,45},value=168,type=1,reward={21001,21002,21003},sort=2,kind=1,},

}
local empty_table = {}
local default_value = {
    name = "累充礼包第一档",
lockGift = 0,
condition = {1,2},
param = {2,45},
value = 30,
type = 1,
reward = {21004,21005,21006},
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
for _, v in pairs(cumulativeGiftConfig) do
    setmetatable(v, metatable)
end
 
return cumulativeGiftConfig
