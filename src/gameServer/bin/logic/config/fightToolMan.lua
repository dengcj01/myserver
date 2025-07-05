--keys:id|professionType|professionName_langId|professionIcon|icon|bodyImg|modelId|openLevel|equiptSlot1|equiptSlot2|equiptSlot3|equiptSlot4|equiptSlot5|equiptSlot6|chatSuccessContent_langId|chatFailContent_langId|discountContent_langId|riseInPriceContent_langId|chatHiContent_langId|payMoreContent_langId|payLessContent_langId|refuseContent_langId|unfitContent_langId|
local fightToolMan={
[1]={id=1,professionType=1,professionName_langId="龙城",professionIcon="1752",icon="yingxiong",bodyImg="temp",modelId="Hero",openLevel=1,equiptSlot1={1,2,4,5},equiptSlot2={11},equiptSlot3={14},equiptSlot4={17},equiptSlot5={19},equiptSlot6={25,22,26},chatSuccessContent_langId="1",chatFailContent_langId="2",discountContent_langId="3",riseInPriceContent_langId="4",chatHiContent_langId="5",payMoreContent_langId="6",payLessContent_langId="7",refuseContent_langId="8",unfitContent_langId="9",},
[2]={id=2,professionType=1,professionName_langId="破阵",professionIcon="1752",icon="yingxiong",bodyImg="boss",modelId="Hero",openLevel=1,equiptSlot1={2,4,5,10},equiptSlot2={11,12},equiptSlot3={14},equiptSlot4={17},equiptSlot5={19},equiptSlot6={22,26,24},chatSuccessContent_langId="1",chatFailContent_langId="2",discountContent_langId="3",riseInPriceContent_langId="4",chatHiContent_langId="5",payMoreContent_langId="6",payLessContent_langId="7",refuseContent_langId="8",unfitContent_langId="9",},
[3]={id=3,professionType=2,professionName_langId="急羽",professionIcon="1752",icon="yingxiong",bodyImg="temp",modelId="Hero",openLevel=1,equiptSlot1={6,3,1,10},equiptSlot2={12,13},equiptSlot3={15,16},equiptSlot4={18},equiptSlot5={20},equiptSlot6={25,24,26},chatSuccessContent_langId="1",chatFailContent_langId="2",discountContent_langId="3",riseInPriceContent_langId="4",chatHiContent_langId="5",payMoreContent_langId="6",payLessContent_langId="7",refuseContent_langId="8",unfitContent_langId="9",},
[4]={id=4,professionType=2,professionName_langId="暗刑",professionIcon="1752",icon="yingxiong",bodyImg="boss",modelId="Hero",openLevel=1,equiptSlot1={1,3,5,9},equiptSlot2={11,12},equiptSlot3={15,14},equiptSlot4={17,18},equiptSlot5={19,20},equiptSlot6={21,22,23},chatSuccessContent_langId="1",chatFailContent_langId="2",discountContent_langId="3",riseInPriceContent_langId="4",chatHiContent_langId="5",payMoreContent_langId="6",payLessContent_langId="7",refuseContent_langId="8",unfitContent_langId="9",},
[5]={id=5,professionType=3,professionName_langId="御法",professionIcon="1752",icon="yingxiong",bodyImg="temp",modelId="Hero",openLevel=2,equiptSlot1={7,6,8,9},equiptSlot2={13},equiptSlot3={16},equiptSlot4={18},equiptSlot5={20},equiptSlot6={23,24,21},chatSuccessContent_langId="1",chatFailContent_langId="2",discountContent_langId="3",riseInPriceContent_langId="4",chatHiContent_langId="5",payMoreContent_langId="6",payLessContent_langId="7",refuseContent_langId="8",unfitContent_langId="9",},
[6]={id=6,professionType=3,professionName_langId="司命",professionIcon="1752",icon="yingxiong",bodyImg="boss",modelId="Hero",openLevel=2,equiptSlot1={7,3,2,8},equiptSlot2={12,13},equiptSlot3={16,15,14},equiptSlot4={17,18},equiptSlot5={19,20},equiptSlot6={23,25,21},chatSuccessContent_langId="1",chatFailContent_langId="2",discountContent_langId="3",riseInPriceContent_langId="4",chatHiContent_langId="5",payMoreContent_langId="6",payLessContent_langId="7",refuseContent_langId="8",unfitContent_langId="9",},

}
local empty_table = {}
local default_value = {
    professionType = 1,
professionName_langId = "龙城",
professionIcon = "1752",
icon = "yingxiong",
bodyImg = "temp",
modelId = "Hero",
openLevel = 1,
equiptSlot1 = {1,2,4,5},
equiptSlot2 = {11},
equiptSlot3 = {14},
equiptSlot4 = {17},
equiptSlot5 = {19},
equiptSlot6 = {25,22,26},
chatSuccessContent_langId = "1",
chatFailContent_langId = "2",
discountContent_langId = "3",
riseInPriceContent_langId = "4",
chatHiContent_langId = "5",
payMoreContent_langId = "6",
payLessContent_langId = "7",
refuseContent_langId = "8",
unfitContent_langId = "9",

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
for _, v in pairs(fightToolMan) do
    setmetatable(v, metatable)
end
 
return fightToolMan
