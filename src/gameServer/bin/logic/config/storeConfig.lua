--keys:id|name|index|bgIcon|defaultOpen|openAdv|startDate|period|refreshTime|refreshCost|refreshCnt|refreshCostType|refreshCostCount|goodsCount|topRes|showBtn|storeTalk|
local storeConfig={
[101]={id=101,name="琅琊杂货",index=1,bgIcon="",defaultOpen=1,openAdv=0,startDate={2024,2,1,1,11,1},period=0,refreshTime=0,refreshCost={{3,2,0},{3,2,0},{3,2,5},{3,2,10},{3,2,20},{3,2,20},{3,2,30},{3,2,30},{3,2,40},{3,2,50},{3,2,80},{3,2,100}},refreshCnt=20,refreshCostType={},refreshCostCount=0,goodsCount=20,topRes={1,2},showBtn=0,storeTalk=14,},
[102]={id=102,name="紫府秘宝",index=2,bgIcon="",defaultOpen=1,openAdv=0,startDate={2024,2,1,1,11,1},period=0,refreshTime=0,refreshCost={},refreshCnt=0,refreshCostType={},refreshCostCount=0,goodsCount=0,topRes={13},showBtn=0,storeTalk=14,},

}
local empty_table = {}
local default_value = {
    name = "琅琊杂货",
index = 1,
bgIcon = "",
defaultOpen = 1,
openAdv = 0,
startDate = {2024,2,1,1,11,1},
period = 0,
refreshTime = 0,
refreshCost = {{3,2,0},{3,2,0},{3,2,5},{3,2,10},{3,2,20},{3,2,20},{3,2,30},{3,2,30},{3,2,40},{3,2,50},{3,2,80},{3,2,100}},
refreshCnt = 20,
refreshCostType = {},
refreshCostCount = 0,
goodsCount = 20,
topRes = {1,2},
showBtn = 0,
storeTalk = 14,

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
for _, v in pairs(storeConfig) do
    setmetatable(v, metatable)
end
 
return storeConfig
