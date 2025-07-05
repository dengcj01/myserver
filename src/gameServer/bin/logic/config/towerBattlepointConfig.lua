--keys:eventID|monsterId|formation|bg_battleShowPic|
local towerBattlepointConfig={
[10001]={eventID=10001,monsterId={{1001401,1},{1000101,1}},formation=1,bg_battleShowPic="bg_cangxueshenshan",},
[10002]={eventID=10002,monsterId={{1000302,1},{1000502,1},{1000102,1},{1000602,1}},formation=1,bg_battleShowPic="bg_qingqiuxu",},
[10003]={eventID=10003,monsterId={{1001003,1},{1000603,1},{1000303,1},{1000403,1}},formation=1,bg_battleShowPic="bg_lingyunfeng",},
[10004]={eventID=10004,monsterId={{1000703,1},{1000603,1},{1000403,1},{1001003,1}},formation=1,bg_battleShowPic="bg_yinyuedong",},

}
local empty_table = {}
local default_value = {
    monsterId = {{1001401,1},{1000101,1}},
formation = 1,
bg_battleShowPic = "bg_cangxueshenshan",

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
for _, v in pairs(towerBattlepointConfig) do
    setmetatable(v, metatable)
end
 
return towerBattlepointConfig
