--keys:quantityId|Exp|
local equipLevelup={
[1]={quantityId=1,Exp={},},
[2]={quantityId=2,Exp={30,60,90,120,160,333,507,640},},
[3]={quantityId=3,Exp={30,60,90,120,160,333,507,640,1400,2160,2920,3680},},
[4]={quantityId=4,Exp={30,60,90,120,160,333,507,640,1400,2160,2920,3680,4440,6880,9320,11760},},
[5]={quantityId=5,Exp={30,60,90,120,160,333,507,640,1400,2160,2920,3680,4440,6880,9320,11760,14200,21400,28600,35800},},

}
local empty_table = {}
local default_value = {
    Exp = {},

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
for _, v in pairs(equipLevelup) do
    setmetatable(v, metatable)
end
 
return equipLevelup
