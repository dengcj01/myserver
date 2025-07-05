--keys:id|activity_type|date_type|date|openday|show|ratio|power|activity_switch|sheetId|functionId|popupType|
local activitytimeConfig={
[1]={id=1,activity_type=1,date_type=1,date={1,10},openday=0,show=1,ratio="七日目标",power=1,activity_switch=1,sheetId=1,functionId=0,popupType=0,},
[2]={id=2,activity_type=2,date_type=4,date={1,999},openday=0,show=2,ratio="八日签到",power=2,activity_switch=1,sheetId=1,functionId=2000,popupType=1,},
[3]={id=3,activity_type=3,date_type=4,date={1,999},openday=0,show=3,ratio="邮件",power=3,activity_switch=1,sheetId=1,functionId=0,popupType=0,},

}
local empty_table = {}
local default_value = {
    activity_type = 1,
date_type = 1,
date = {1,10},
openday = 0,
show = 1,
ratio = "七日目标",
power = 1,
activity_switch = 1,
sheetId = 1,
functionId = 0,
popupType = 0,

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
for _, v in pairs(activitytimeConfig) do
    setmetatable(v, metatable)
end
 
return activitytimeConfig
