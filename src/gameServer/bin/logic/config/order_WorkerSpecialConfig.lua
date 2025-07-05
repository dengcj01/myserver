--keys:id|npcType|
local order_WorkerSpecialConfig={
[1]={id=1,npcType={[1]={{npc=121,level=7,taskId=0,sellTime={{1800,3600},{3600,7200},{7200,14400},{7200,14400}},},},[2]={{npc=107,level=20,taskId=0,sellTime={{120,300},{240,720},{1800,3600},{3600,7200},{7200,14400},{7200,14400}},},},[3]={{npc=17,level=40,taskId=0,sellTime={{120,300},{240,720},{1800,3600},{3600,7200},{7200,14400}},},},[4]={{npc=114,level=60,taskId=0,sellTime={{120,300},{240,720},{1800,3600},{3600,7200}},},},},},
[2]={id=2,npcType={[1]={{npc=702,level=7,taskId=0,sellTime={{1800,3600},{3600,7200},{7200,14400},{7200,14400}},},},[2]={{npc=109,level=20,taskId=0,sellTime={{120,300},{240,720},{1800,3600},{3600,7200},{7200,14400},{7200,14400}},},},[3]={{npc=111,level=40,taskId=0,sellTime={{120,300},{240,720},{1800,3600},{3600,7200},{7200,14400}},},},[4]={{npc=108,level=60,taskId=0,sellTime={{120,300},{240,720},{1800,3600},{3600,7200}},},},},},

}
local empty_table = {}
local default_value = {
    {[1]={{npc=121,level=7,taskId=0,sellTime={{1800,3600},{3600,7200},{7200,14400},{7200,14400}},},},[2]={{npc=107,level=20,taskId=0,sellTime={{120,300},{240,720},{1800,3600},{3600,7200},{7200,14400},{7200,14400}},},},[3]={{npc=17,level=40,taskId=0,sellTime={{120,300},{240,720},{1800,3600},{3600,7200},{7200,14400}},},},[4]={{npc=114,level=60,taskId=0,sellTime={{120,300},{240,720},{1800,3600},{3600,7200}},},},},npcType = 1,

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
for _, v in pairs(order_WorkerSpecialConfig) do
    setmetatable(v, metatable)
end
 
return order_WorkerSpecialConfig
