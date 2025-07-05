--keys:id|exp|gem|skill|
local player={
[1]={id=1,exp=0,gem=0,skill={{1,100},{2,200}},},

}
local empty_table = {}
local default_value = {
    exp = 0,
gem = 0,
skill = {{1,100},{2,200}},

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
for _, v in pairs(player) do
    setmetatable(v, metatable)
end
 
return player
