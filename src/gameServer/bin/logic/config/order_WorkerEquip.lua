--keys:id|loop|level|taskId|sellTime|workerSellUseCount|
local order_WorkerEquip={
[1]={id=1,loop=1,level=4,taskId=0,sellTime={{1800,3600},{3600,7200},{7200,14400},{7200,14400}},workerSellUseCount=5,},
[2]={id=2,loop=1,level=10,taskId=0,sellTime={{120,300},{240,720},{1800,3600},{3600,7200},{7200,14400},{7200,14400}},workerSellUseCount=5,},
[3]={id=3,loop=1,level=15,taskId=0,sellTime={{120,300},{240,720},{1800,3600},{3600,7200},{7200,14400}},workerSellUseCount=5,},
[4]={id=4,loop=1,level=20,taskId=0,sellTime={{120,300},{240,720},{1800,3600},{3600,7200}},workerSellUseCount=5,},

}
local empty_table = {}
local default_value = {
    loop = 1,
level = 4,
taskId = 0,
sellTime = {{1800,3600},{3600,7200},{7200,14400},{7200,14400}},
workerSellUseCount = 5,

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
for _, v in pairs(order_WorkerEquip) do
    setmetatable(v, metatable)
end
 
return order_WorkerEquip
