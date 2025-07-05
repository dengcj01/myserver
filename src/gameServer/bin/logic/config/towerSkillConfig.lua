--keys:id|buffStore|
local towerSkillConfig={
[1]={id=1,buffStore={[1]={{id=10001,weight=1500,},{id=10002,weight=1500,},{id=10003,weight=1500,},{id=10004,weight=1500,},{id=10005,weight=1500,},{id=10006,weight=2500,},},},},
[2]={id=2,buffStore={[2]={{id=10007,weight=2500,},{id=10008,weight=2500,},{id=10009,weight=2500,},{id=10010,weight=2500,},{id=10011,weight=2500,},{id=10012,weight=2500,},},},},
[3]={id=3,buffStore={[3]={{id=10013,weight=300,},{id=10014,weight=300,},{id=10015,weight=300,},{id=10016,weight=300,},},},},

}
local empty_table = {}
local default_value = {
    {[1]={{id=10001,weight=1500,},{id=10002,weight=1500,},{id=10003,weight=1500,},{id=10004,weight=1500,},{id=10005,weight=1500,},{id=10006,weight=2500,},},},buffStore = 1,

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
for _, v in pairs(towerSkillConfig) do
    setmetatable(v, metatable)
end
 
return towerSkillConfig
