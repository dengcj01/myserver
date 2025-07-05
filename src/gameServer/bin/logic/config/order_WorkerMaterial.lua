--keys:id|loop|level|taskId|sellTime|workerSellMaterialCount|
local order_WorkerMaterial={
[1]={id=1,loop=1,level=3,taskId=0,sellTime={{60,120},{180,300},{180,300},{180,300},{180,300},{180,300},{180,300},{180,300},{450,750},{450,750}},workerSellMaterialCount={0.5,0.8},},
[2]={id=2,loop=1,level=10,taskId=0,sellTime={{60,120},{180,300},{180,300},{180,300},{900,1800}},workerSellMaterialCount={0.25,0.4},},
[3]={id=3,loop=1,level=15,taskId=0,sellTime={{60,120},{180,300},{900,3600},{1800,3600},{3600,7200}},workerSellMaterialCount={0.25,0.4},},
[4]={id=4,loop=1,level=20,taskId=0,sellTime={{60,120},{180,300},{900,3600},{1800,3600},{3600,7200}},workerSellMaterialCount={0.25,0.4},},
[5]={id=5,loop=1,level=25,taskId=0,sellTime={{60,120},{180,300},{900,3600},{1800,3600},{3600,7200}},workerSellMaterialCount={0.25,0.4},},
[6]={id=6,loop=1,level=30,taskId=0,sellTime={{60,120},{180,300},{900,3600},{1800,3600},{3600,7200}},workerSellMaterialCount={0.25,0.4},},

}
local empty_table = {}
local default_value = {
    loop = 1,
level = 3,
taskId = 0,
sellTime = {{60,120},{180,300},{180,300},{180,300},{180,300},{180,300},{180,300},{180,300},{450,750},{450,750}},
workerSellMaterialCount = {0.5,0.8},

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
for _, v in pairs(order_WorkerMaterial) do
    setmetatable(v, metatable)
end
 
return order_WorkerMaterial
