--keys:id|equipIds|hiddenNode|
local hiddenEquipConfig={
[1]={id=1,equipIds={14001,14002,14003,14004,14005,14006,14007,16003,16004,15103},hiddenNode="Su_toufa",},
[2]={id=2,equipIds={14103,15103},hiddenNode="Su_toufa4_mao",},

}
local empty_table = {}
local default_value = {
    equipIds = {14001,14002,14003,14004,14005,14006,14007,16003,16004,15103},
hiddenNode = "Su_toufa",

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
for _, v in pairs(hiddenEquipConfig) do
    setmetatable(v, metatable)
end
 
return hiddenEquipConfig
