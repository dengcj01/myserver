--keys:id|type|form|
local orderConfig={
[1]={id=1,type=1,form="",},
[2]={id=2,type=2,form="order_CustomerEquip",},
[3]={id=3,type=3,form="order_HeroEquip",},
[4]={id=4,type=4,form="order_Princess",},
[5]={id=5,type=5,form="order_WorkerMaterial",},
[6]={id=6,type=6,form="",},
[7]={id=7,type=7,form="order_WorkerEquip",},

}

local default_value = {
    type = 1,
form = "",

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
for _, v in pairs(orderConfig) do
    setmetatable(v, metatable)
end
 
return orderConfig
