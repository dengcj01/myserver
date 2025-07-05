--keys:id|name|skillId|type|
local talentNature={
[1]={id=1,name="玲珑",skillId=500001,type={{1,5000},{7,5000}},},
[2]={id=2,name="慧心",skillId=500002,type={{2,5000},{6,5000}},},
[3]={id=3,name="胸怀万策",skillId=500003,type={{3,5000},{9,5000}},},
[4]={id=4,name="争锋",skillId=500004,type={{4,5000},{8,5000}},},
[5]={id=5,name="谋定后动",skillId=500005,type={{5,5000},{8,5000}},},
[6]={id=6,name="向阳",skillId=500006,type={{1,5000},{2,5000}},},

}
local empty_table = {}
local default_value = {
    name = "玲珑",
skillId = 500001,
type = {{1,5000},{7,5000}},

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
for _, v in pairs(talentNature) do
    setmetatable(v, metatable)
end
 
return talentNature
