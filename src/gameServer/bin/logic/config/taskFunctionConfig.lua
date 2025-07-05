--keys:id|range1|range2|refreshTime|dailyTaskRefreshTime|upperLimit|
local taskFunctionConfig={
[1]={id=1,range1={1,9999},range2={},refreshTime=0,dailyTaskRefreshTime=0,upperLimit=0,},
[2]={id=2,range1={10000,19999},range2={},refreshTime=14400,dailyTaskRefreshTime=99,upperLimit=1,},
[3]={id=3,range1={20000,29999},range2={},refreshTime=0,dailyTaskRefreshTime=0,upperLimit=0,},
[4]={id=4,range1={30000,34999},range2={},refreshTime=0,dailyTaskRefreshTime=0,upperLimit=0,},
[5]={id=5,range1={35000,39999},range2={},refreshTime=0,dailyTaskRefreshTime=0,upperLimit=0,},
[6]={id=6,range1={60000,69999},range2={},refreshTime=0,dailyTaskRefreshTime=0,upperLimit=0,},

}
local empty_table = {}
local default_value = {
    range1 = {1,9999},
range2 = {},
refreshTime = 0,
dailyTaskRefreshTime = 0,
upperLimit = 0,

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
for _, v in pairs(taskFunctionConfig) do
    setmetatable(v, metatable)
end
 
return taskFunctionConfig
