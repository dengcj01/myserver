--keys:id|npc|sellMaterial|sellEquip|build|
local order_people={
[1]={id=1,npc=15,sellMaterial=0,sellEquip={1,2,3,11,14,17,19},build=0,},
[2]={id=2,npc=107,sellMaterial=0,sellEquip={4,5,6,7},build=0,},
[3]={id=3,npc=17,sellMaterial=0,sellEquip={12,13,15,16,18,20},build=0,},
[4]={id=4,npc=114,sellMaterial=0,sellEquip={23,25,24,22,20,19},build=0,},
[5]={id=5,npc=19,sellMaterial=0,sellEquip={26},build=0,},
[6]={id=6,npc=109,sellMaterial=0,sellEquip={24,25,4},build=0,},
[7]={id=7,npc=111,sellMaterial=0,sellEquip={21,22},build=0,},
[8]={id=8,npc=108,sellMaterial=0,sellEquip={3},build=0,},
[9]={id=9,npc=16,sellMaterial=0,sellEquip={8,26},build=0,},
[10]={id=10,npc=113,sellMaterial=0,sellEquip={9,10},build=0,},
[11]={id=11,npc=5,sellMaterial=2001,sellEquip={},build=0,},
[12]={id=12,npc=6,sellMaterial=2002,sellEquip={},build=0,},
[13]={id=13,npc=7,sellMaterial=2003,sellEquip={},build=0,},
[14]={id=14,npc=8,sellMaterial=2004,sellEquip={},build=0,},
[15]={id=15,npc=22,sellMaterial=2005,sellEquip={},build=0,},
[16]={id=16,npc=10,sellMaterial=2006,sellEquip={},build=0,},
[17]={id=17,npc=11,sellMaterial=2007,sellEquip={},build=0,},
[18]={id=18,npc=12,sellMaterial=2008,sellEquip={},build=0,},
[19]={id=19,npc=13,sellMaterial=2009,sellEquip={},build=0,},
[20]={id=20,npc=14,sellMaterial=2010,sellEquip={},build=0,},
[21]={id=21,npc=13,sellMaterial=2011,sellEquip={},build=0,},
[22]={id=22,npc=14,sellMaterial=2012,sellEquip={},build=0,},

}
local empty_table = {}
local default_value = {
    npc = 15,
sellMaterial = 0,
sellEquip = {1,2,3,11,14,17,19},
build = 0,

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
for _, v in pairs(order_people) do
    setmetatable(v, metatable)
end
 
return order_people
