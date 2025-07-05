--keys:id|initProductSlotNum|extendSlotParam|artifactChangeCd|artifactShelfId|armorShelfId|defaultFloorId|defaultWallId|shopUpgradeParam|zoomOutParam|zoomInParam|matLowLimit|princessEnterInfo|giveNumber|giveProportion|giveCondition|giveCD|npcLimit|
local shopConfig={
[0]={id=0,initProductSlotNum=1,extendSlotParam={{2,0,0,1},{3,7500,140,10},{4,30000,240,15},{5,109500,420,20},{6,330000,520,25},{7,1005000,640,28},{8,2850000,800,30},{9,7200000,1080,32},{10,15000000,1580,35}},artifactChangeCd=4,artifactShelfId=111,armorShelfId=1001,defaultFloorId=2001,defaultWallId=3001,shopUpgradeParam={{1,5000,70,60,10,300,16},{2,20000,120,100,15,600,18},{3,73000,260,180,20,2400,27},{4,220000,400,240,25,4800,27},{5,670000,480,280,30,6000,27},{6,1900000,760,360,35,12000,36},{7,4800000,1280,480,40,24000,36},{8,10000000,1900,700,45,36000,36},{9,0,0,0,50,0,36}},zoomOutParam={0.32,0,16},zoomInParam={1.5,660,-125},matLowLimit=0.2,princessEnterInfo={1,0.5,1.5},giveNumber=10,giveProportion={0.5,0.8},giveCondition=1,giveCD={10,20},npcLimit=5,},

}
local empty_table = {}
local default_value = {
    initProductSlotNum = 1,
extendSlotParam = {{2,0,0,1},{3,7500,140,10},{4,30000,240,15},{5,109500,420,20},{6,330000,520,25},{7,1005000,640,28},{8,2850000,800,30},{9,7200000,1080,32},{10,15000000,1580,35}},
artifactChangeCd = 4,
artifactShelfId = 111,
armorShelfId = 1001,
defaultFloorId = 2001,
defaultWallId = 3001,
shopUpgradeParam = {{1,5000,70,60,10,300,16},{2,20000,120,100,15,600,18},{3,73000,260,180,20,2400,27},{4,220000,400,240,25,4800,27},{5,670000,480,280,30,6000,27},{6,1900000,760,360,35,12000,36},{7,4800000,1280,480,40,24000,36},{8,10000000,1900,700,45,36000,36},{9,0,0,0,50,0,36}},
zoomOutParam = {0.32,0,16},
zoomInParam = {1.5,660,-125},
matLowLimit = 0.2,
princessEnterInfo = {1,0.5,1.5},
giveNumber = 10,
giveProportion = {0.5,0.8},
giveCondition = 1,
giveCD = {10,20},
npcLimit = 5,

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
for _, v in pairs(shopConfig) do
    setmetatable(v, metatable)
end
 
return shopConfig
