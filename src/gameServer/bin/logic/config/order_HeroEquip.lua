--keys:id|num|loop|level|sellTime|delegateCount|heroID|
local order_HeroEquip={
[1]={id=1,num=1,loop=0,level=12,sellTime={1,2},delegateCount={3,8},heroID=25,},
[2]={id=2,num=2,loop=0,level=12,sellTime={1,2},delegateCount={5,5},heroID=3,},
[3]={id=3,num=1,loop=1,level=13,sellTime={1,2},delegateCount={3,8},heroID=0,},
[4]={id=4,num=2,loop=1,level=13,sellTime={1800,1800},delegateCount={3,8},heroID=0,},
[5]={id=5,num=3,loop=1,level=13,sellTime={3600,3600},delegateCount={3,8},heroID=0,},
[6]={id=6,num=4,loop=1,level=13,sellTime={3600,7200},delegateCount={3,8},heroID=0,},
[7]={id=7,num=5,loop=1,level=13,sellTime={3600,7200},delegateCount={3,8},heroID=0,},
[8]={id=8,num=1,loop=1,level=30,sellTime={180,300},delegateCount={3,8},heroID=0,},
[9]={id=9,num=2,loop=1,level=30,sellTime={300,1500},delegateCount={3,8},heroID=0,},
[10]={id=10,num=3,loop=1,level=30,sellTime={1080,1800},delegateCount={3,8},heroID=0,},
[11]={id=11,num=4,loop=1,level=30,sellTime={3600,7200},delegateCount={3,8},heroID=0,},
[12]={id=12,num=5,loop=1,level=30,sellTime={3600,7200},delegateCount={3,8},heroID=0,},
[13]={id=13,num=6,loop=1,level=30,sellTime={3600,7200},delegateCount={3,8},heroID=0,},
[14]={id=14,num=1,loop=1,level=60,sellTime={1,20},delegateCount={3,8},heroID=0,},
[15]={id=15,num=2,loop=1,level=60,sellTime={180,300},delegateCount={3,8},heroID=0,},
[16]={id=16,num=3,loop=1,level=60,sellTime={300,1500},delegateCount={3,8},heroID=0,},
[17]={id=17,num=4,loop=1,level=60,sellTime={1080,1800},delegateCount={3,8},heroID=0,},
[18]={id=18,num=5,loop=1,level=60,sellTime={10800,18000},delegateCount={3,8},heroID=0,},
[19]={id=19,num=1,loop=1,level=100,sellTime={1,20},delegateCount={3,8},heroID=0,},
[20]={id=20,num=2,loop=1,level=100,sellTime={180,300},delegateCount={3,8},heroID=0,},
[21]={id=21,num=3,loop=1,level=100,sellTime={300,1500},delegateCount={3,8},heroID=0,},
[22]={id=22,num=4,loop=1,level=100,sellTime={10800,18000},delegateCount={3,8},heroID=0,},

}
local empty_table = {}
local default_value = {
    num = 1,
loop = 0,
level = 12,
sellTime = {1,2},
delegateCount = {3,8},
heroID = 25,

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
for _, v in pairs(order_HeroEquip) do
    setmetatable(v, metatable)
end
 
return order_HeroEquip
