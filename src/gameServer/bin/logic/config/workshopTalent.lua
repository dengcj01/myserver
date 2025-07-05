--keys:id|name|description|time|double|bargaining|love|priceUp|buy|weaponProduction|additionalWeapons|armorProduction|additionalArmaor|jewelryProduction|additionalJewelry|gatherPlace|gatherOutput|alchemy|alchemyTime|
local workshopTalent={
[1]={id=1,name="客流开拓",description="来客到店速度提升%d",time={125,250,375,500,625,750,875,1000,1125,1250,1375,1500,1625,1750,1875,2000,2125,2250,2375,2500},double={},bargaining={},love={},priceUp={},buy={},weaponProduction={},additionalWeapons={},armorProduction={},additionalArmaor={},jewelryProduction={},additionalJewelry={},gatherPlace={},gatherOutput={},alchemy={},alchemyTime={},},
[2]={id=2,name="声誉鹊起",description="来客结伴的概率提升%d",time={},double={250,500,750,1000,1250,1500,1750,2000,2250,2500,2750,3000,3250,3500,3750,4000,4250,4500,4750,5000},bargaining={},love={},priceUp={},buy={},weaponProduction={},additionalWeapons={},armorProduction={},additionalArmaor={},jewelryProduction={},additionalJewelry={},gatherPlace={},gatherOutput={},alchemy={},alchemyTime={},},
[3]={id=3,name="讨价还价",description="商品涨价幅度额外提升%d",time={},double={},bargaining={125,250,375,500,625,750,875,1000,1125,1250,1375,1500,1625,1750,1875,2000,2125,2250,2375,2500,2625,2750,2875,3000,3125,3250,3375,3500,3625,3750,3875,4000,4125,4250,4375,4500},love={},priceUp={},buy={},weaponProduction={},additionalWeapons={},armorProduction={},additionalArmaor={},jewelryProduction={},additionalJewelry={},gatherPlace={},gatherOutput={},alchemy={},alchemyTime={},},
[4]={id=4,name="微笑服务",description="商品降价获得的满意度增加%d；商品涨价出扣除的满意度下降%d",time={},double={},bargaining={},love={{125,125},{250,250},{375,375},{500,500},{625,625},{750,750},{875,875},{1000,1000},{1125,1125},{1250,1250},{1375,1375},{1500,1500},{1625,1625},{1750,1750},{1875,1875},{2000,2000},{2125,2125},{2250,2250},{2375,2375},{2500,2500},{2625,2625},{2750,2750},{2875,2875},{3000,3000},{3125,3125},{3250,3250},{3375,3375},{3500,3500},{3625,3625},{3750,3750},{3875,3875},{4000,4000},{4125,4125},{4250,4250},{4375,4375},{4500,4500}},priceUp={},buy={},weaponProduction={},additionalWeapons={},armorProduction={},additionalArmaor={},jewelryProduction={},additionalJewelry={},gatherPlace={},gatherOutput={},alchemy={},alchemyTime={},},
[5]={id=5,name="狮子开口",description="商品基础售价提升%d",time={},double={},bargaining={},love={},priceUp={125,250,375,500,625,750,875,1000,1125,1250,1375,1500,1625,1750,1875,2000,2125,2250,2375,2500,2625,2750,2875,3000,3125,3250,3375,3500,3625,3750,3875,4000,4125,4250,4375,4500},buy={},weaponProduction={},additionalWeapons={},armorProduction={},additionalArmaor={},jewelryProduction={},additionalJewelry={},gatherPlace={},gatherOutput={},alchemy={},alchemyTime={},},
[6]={id=6,name="打包促销",description="客人多购买1件商品的概率提升%d",time={},double={},bargaining={},love={},priceUp={},buy={125,250,375,500,625,750,875,1000,1125,1250,1375,1500,1625,1750,1875,2000,2125,2250,2375,2500,2625,2750,2875,3000,3125,3250,3375,3500,3625,3750,3875,4000,4125,4250,4375,4500},weaponProduction={},additionalWeapons={},armorProduction={},additionalArmaor={},jewelryProduction={},additionalJewelry={},gatherPlace={},gatherOutput={},alchemy={},alchemyTime={},},
[7]={id=7,name="百炼成钢",description="武器的制造时间缩短%d",time={},double={},bargaining={},love={},priceUp={},buy={},weaponProduction={125,250,375,500,625,750,875,1000,1125,1250,1375,1500,1625,1750,1875,2000,2125,2250,2375,2500,2625,2750,2875,3000,3125,3250,3375,3500,3625,3750,3875,4000,4125,4250,4375,4500},additionalWeapons={},armorProduction={},additionalArmaor={},jewelryProduction={},additionalJewelry={},gatherPlace={},gatherOutput={},alchemy={},alchemyTime={},},
[8]={id=8,name="鬼斧神工",description="制造武器时，%d额外获得一件",time={},double={},bargaining={},love={},priceUp={},buy={},weaponProduction={},additionalWeapons={50,100,150,200,250,300,350,400,450,500,550,600,650,700,750,800,850,900,950,1000,1050,1100,1150,1200,1250,1300,1350,1400,1450,1500,1550,1600,1650,1700,1750,1800},armorProduction={},additionalArmaor={},jewelryProduction={},additionalJewelry={},gatherPlace={},gatherOutput={},alchemy={},alchemyTime={},},
[9]={id=9,name="精工细作",description="防具的制造时间缩短%d",time={},double={},bargaining={},love={},priceUp={},buy={},weaponProduction={},additionalWeapons={},armorProduction={125,250,375,500,625,750,875,1000,1125,1250,1375,1500,1625,1750,1875,2000,2125,2250,2375,2500,2625,2750,2875,3000,3125,3250,3375,3500,3625,3750,3875,4000,4125,4250,4375,4500},additionalArmaor={},jewelryProduction={},additionalJewelry={},gatherPlace={},gatherOutput={},alchemy={},alchemyTime={},},
[10]={id=10,name="匠心独运",description="制造防具时，%d额外获得一件",time={},double={},bargaining={},love={},priceUp={},buy={},weaponProduction={},additionalWeapons={},armorProduction={},additionalArmaor={50,100,150,200,250,300,350,400,450,500,550,600,650,700,750,800,850,900,950,1000,1050,1100,1150,1200,1250,1300,1350,1400,1450,1500,1550,1600,1650,1700,1750,1800},jewelryProduction={},additionalJewelry={},gatherPlace={},gatherOutput={},alchemy={},alchemyTime={},},
[11]={id=11,name="精雕细琢",description="饰品的制造时间缩短%d",time={},double={},bargaining={},love={},priceUp={},buy={},weaponProduction={},additionalWeapons={},armorProduction={},additionalArmaor={},jewelryProduction={125,250,375,500,625,750,875,1000,1125,1250,1375,1500,1625,1750,1875,2000,2125,2250,2375,2500,2625,2750,2875,3000,3125,3250,3375,3500,3625,3750,3875,4000,4125,4250,4375,4500},additionalJewelry={},gatherPlace={},gatherOutput={},alchemy={},alchemyTime={},},
[12]={id=12,name="巧夺天工",description="制造饰品时，%d额外获得一件",time={},double={},bargaining={},love={},priceUp={},buy={},weaponProduction={},additionalWeapons={},armorProduction={},additionalArmaor={},jewelryProduction={},additionalJewelry={50,100,150,200,250,300,350,400,450,500,550,600,650,700,750,800,850,900,950,1000,1050,1100,1150,1200,1250,1300,1350,1400,1450,1500,1550,1600,1650,1700,1750,1800},gatherPlace={},gatherOutput={},alchemy={},alchemyTime={},},
[13]={id=13,name="快马加鞭",description="马车存储空间增加%d",time={},double={},bargaining={},love={},priceUp={},buy={},weaponProduction={},additionalWeapons={},armorProduction={},additionalArmaor={},jewelryProduction={},additionalJewelry={},gatherPlace={100,200,300,400,540,680,820,960,1200,1440,1680,1920,2280,2640,3000,3360,3720,4080,4440,4800,5460,6120,6780,7440,8340,9240,10140,11040,12180,13320,14460,15600,17100,18600,20100,21600},gatherOutput={},alchemy={},alchemyTime={},},
[14]={id=14,name="搜罗殚尽",description="采集产量提升%d",time={},double={},bargaining={},love={},priceUp={},buy={},weaponProduction={},additionalWeapons={},armorProduction={},additionalArmaor={},jewelryProduction={},additionalJewelry={},gatherPlace={},gatherOutput={500,1000,1500,2000,2500,3000,3500,4000,4500,5000,5500,6000,6500,7000,7500,8000,8500,9000,9500,10000,10500,11000,11500,12000,12500,13000,13500,14000,14500,15000,15500,16000,16500,17000,17500,18000,18500,19000,19500,20000},alchemy={},alchemyTime={},},
[15]={id=15,name="水火既济",description="灵丹产量提升%d",time={},double={},bargaining={},love={},priceUp={},buy={},weaponProduction={},additionalWeapons={},armorProduction={},additionalArmaor={},jewelryProduction={},additionalJewelry={},gatherPlace={},gatherOutput={},alchemy={625,1250,1875,2500,3125,3750,4375,5000,5625,6250,6875,7500,8125,8750,9375,10000,10625,11250,11875,12500,13125,13750,14375,15000,15625,16250,16875,17500,18125,18750,19375,20000,20625,21250,21875,22500,23125,23750,24375,25000},alchemyTime={},},
[16]={id=16,name="九转丹成",description="炼化所需的时间缩短%d",time={},double={},bargaining={},love={},priceUp={},buy={},weaponProduction={},additionalWeapons={},armorProduction={},additionalArmaor={},jewelryProduction={},additionalJewelry={},gatherPlace={},gatherOutput={},alchemy={},alchemyTime={240,480,720,960,1200,1440,1680,1920,2160,2400,2640,2880,3120,3360,3600,3840,4080,4320,4560,4800,5040,5280,5520,5760,6000,6240,6480,6720,6960,7200,7440,7680,7920,8160,8400,8640,8880,9120,9360,9600},},

}
local empty_table = {}
local default_value = {
    name = "客流开拓",
description = "来客到店速度提升%d",
time = {125,250,375,500,625,750,875,1000,1125,1250,1375,1500,1625,1750,1875,2000,2125,2250,2375,2500},
double = {},
bargaining = {},
love = {},
priceUp = {},
buy = {},
weaponProduction = {},
additionalWeapons = {},
armorProduction = {},
additionalArmaor = {},
jewelryProduction = {},
additionalJewelry = {},
gatherPlace = {},
gatherOutput = {},
alchemy = {},
alchemyTime = {},

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
for _, v in pairs(workshopTalent) do
    setmetatable(v, metatable)
end
 
return workshopTalent
