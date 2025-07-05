--keys:id|name|resource_id|width|height|camera_size|
local map={
[10001]={id=10001,name="经营场景",resource_id="ShopScene",width=62,height=38,camera_size=5,},
[10002]={id=10002,name="广场",resource_id="CityScene",width=48,height=22,camera_size=10,},
[10003]={id=10003,name="战斗",resource_id="BattleScene",width=24,height=15,camera_size=5,},
[10004]={id=10004,name="经营验证",resource_id="OperateScene",width=24,height=15,camera_size=5,},

}

local default_value = {
    name = "经营场景",
resource_id = "ShopScene",
width = 62,
height = 38,
camera_size = 5,

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
for _, v in pairs(map) do
    setmetatable(v, metatable)
end
 
return map
