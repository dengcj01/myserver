--keys:id|level|taskId|loop|sellTime|
local order_CustomerEquip={
[1]={id=1,level=12,taskId=0,loop=0,sellTime={{600,900},{900,1800},{2400,3600},{7200,14400},{10800,18000}},},
[2]={id=2,level=30,taskId=0,loop=1,sellTime={{600,900},{900,1800},{2400,3600},{7200,14400},{10800,18000},{10800,18000},{10800,18000}},},
[3]={id=3,level=60,taskId=0,loop=1,sellTime={{60,240},{300,600},{600,900},{900,1800},{2400,3600},{10800,18000}},},
[4]={id=4,level=100,taskId=0,loop=1,sellTime={{60,240},{600,900},{900,1800},{2400,3600},{10800,18000}},},

}
local empty_table = {}
local default_value = {
    level = 12,
taskId = 0,
loop = 0,
sellTime = {{600,900},{900,1800},{2400,3600},{7200,14400},{10800,18000}},

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
for _, v in pairs(order_CustomerEquip) do
    setmetatable(v, metatable)
end
 
return order_CustomerEquip
