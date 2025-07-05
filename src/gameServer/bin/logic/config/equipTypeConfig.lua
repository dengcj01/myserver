--keys:id|walkAction|idleAction|thinkingAction|getAction|
local equipTypeConfig={
[1]={id=1,walkAction="walk_jian",idleAction="idle_jian",thinkingAction="thinking_jian",getAction="get_jian",},
[2]={id=2,walkAction="walk_dao",idleAction="idle_dao",thinkingAction="thinking_dao",getAction="get_dao",},
[3]={id=3,walkAction="walk_bishou",idleAction="idle_bishou",thinkingAction="thinking_bishou",getAction="get_bishou",},
[4]={id=4,walkAction="walk_chui",idleAction="idle_chui",thinkingAction="thinking_chui",getAction="get_chui",},
[5]={id=5,walkAction="walk_qiang",idleAction="idle_qiang",thinkingAction="thinking_qiang",getAction="get_qiang",},
[6]={id=6,walkAction="walk_gong",idleAction="idle_gong",thinkingAction="thinking_gong",getAction="get_gong",},
[7]={id=7,walkAction="walk_qin",idleAction="idle_qin",thinkingAction="thinking_qin",getAction="get_qin",},
[8]={id=8,walkAction="walk_shan",idleAction="idle_shan",thinkingAction="thinking_shan",getAction="get_shan",},
[9]={id=9,walkAction="walk",idleAction="idle",thinkingAction="thinking",getAction="get",},
[10]={id=10,walkAction="walk_nu",idleAction="idle_nu",thinkingAction="thinking_nu",getAction="get_nu",},

}

local default_value = {
    walkAction = "walk_jian",
idleAction = "idle_jian",
thinkingAction = "thinking_jian",
getAction = "get_jian",

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
for _, v in pairs(equipTypeConfig) do
    setmetatable(v, metatable)
end
 
return equipTypeConfig
