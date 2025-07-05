--keys:lv|name|courseContent|upCondition|resetExpend|resetRestitution|
local courseSystemConfig={
[1]={lv=1,name="初学乍练",courseContent={1,2,3,4},upCondition={100,100,100,100},resetExpend={3,2,20},resetRestitution=70,},
[2]={lv=2,name="日积月累",courseContent={5,6,7,8},upCondition={100,100,100,100},resetExpend={3,2,20},resetRestitution=70,},
[3]={lv=3,name="渐入佳境",courseContent={9,10,11,12},upCondition={100,100,100,100},resetExpend={3,2,20},resetRestitution=70,},
[4]={lv=4,name="触类旁通",courseContent={13,14,15,16},upCondition={100,100,100,100},resetExpend={3,2,20},resetRestitution=70,},
[5]={lv=5,name="饱学多闻",courseContent={17,18,19,20},upCondition={100,100,100,100},resetExpend={3,2,20},resetRestitution=70,},

}
local empty_table = {}
local default_value = {
    name = "初学乍练",
courseContent = {1,2,3,4},
upCondition = {100,100,100,100},
resetExpend = {3,2,20},
resetRestitution = 70,

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
for _, v in pairs(courseSystemConfig) do
    setmetatable(v, metatable)
end
 
return courseSystemConfig
