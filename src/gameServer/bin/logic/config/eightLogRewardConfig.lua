--keys:id|drop|days|
local eightLogRewardConfig={
[1]={id=1,drop={20002,20003},days={[1]={task_award={22001,22002},},[2]={task_award={22003,22004},},[3]={task_award={22003,22004},},[4]={task_award={22003,22004},},[5]={task_award={22003,22004},},[6]={task_award={22003,22004},},[7]={task_award={22005,22006},},[8]={task_award={22005,22006},},},},

}
local empty_table = {}
local default_value = {
    drop = {20002,20003},
days={[1]={task_award={22001,22002},},[2]={task_award={22003,22004},},[3]={task_award={22003,22004},},[4]={task_award={22003,22004},},[5]={task_award={22003,22004},},[6]={task_award={22003,22004},},[7]={task_award={22005,22006},},[8]={task_award={22005,22006},},},
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
for _, v in pairs(eightLogRewardConfig) do
    setmetatable(v, metatable)
end
 
return eightLogRewardConfig
