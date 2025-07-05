--keys:id|heroName|range|position|nature|num|name|description|icon|
local talentBusiness={
[111]={id=111,heroName="苒苒",range=2,position=0,nature=0,num={{13,1500,1},{14,1500,1},{15,1500,1},{16,1500,1}},name="大快朵颐！",description="苒苒左方以及右方的一位门客，各项属性提升15%",icon="",},
[211]={id=211,heroName="碧影",range=5,position=0,nature=0,num={{14,6000,1}},name="并蒂",description="碧影左方第一位门客，风度提升60%",icon="",},
[311]={id=311,heroName="叶云天",range=3,position=0,nature=0,num={{14,6000,1}},name="若定",description="叶云天右方一位门客，风度提升60%",icon="",},
[411]={id=411,heroName="辰无音",range=8,position=0,nature=0,num={{15,2000,1}},name="弦外有音",description="设施内除辰无音以外的所有门客，运筹提升20%",icon="",},
[511]={id=511,heroName="神天织",range=7,position=0,nature=6,num={{13,1500,1},{14,1500,1},{15,1500,1},{16,1500,1}},name="烈阳灼灼",description="设施内所有向阳性格的门客，各项属性提升15%",icon="",},
[611]={id=611,heroName="荆高手",range=7,position=0,nature=6,num={{14,3000,1}},name="同乐",description="设施内所有向阳性格的门客，风度提升30%",icon="",},
[711]={id=711,heroName="紫紫",range=9,position=0,nature=0,num={{13,1000,1},{14,1000,1},{15,1000,1},{16,1000,1}},name="蛊心",description="设施内除紫紫以外，每增加一名门客，紫紫自身各项属性提升10%",icon="",},
[811]={id=811,heroName="凤烨",range=4,position=0,nature=0,num={{16,6000,1}},name="势焰",description="凤烨右方的两位门客，反应提升60%",icon="",},
[911]={id=911,heroName="小璇",range=6,position=0,nature=0,num={{16,6000,1}},name="出如脱兔",description="小璇左方的两位门客，反应提升60%",icon="",},
[1011]={id=1011,heroName="摩妮莎",range=7,position=0,nature=1,num={{13,1500,1},{14,1500,1},{15,1500,1},{16,1500,1}},name="酒酣耳热",description="设施内所有玲珑性格的门客，各项属性提升15%",icon="",},
[1111]={id=1111,heroName="墨樱",range=7,position=0,nature=0,num={{13,1500,1},{14,1500,1},{15,1500,1},{16,1500,1}},name="周虑",description="设施内所有胸怀万策性格的门客，各项属性提升15%",icon="",},
[1211]={id=1211,heroName="苏语",range=1,position=5,nature=0,num={{15,6000,1}},name="运筹帷幄",description="当苏语处于5号位时，自身运筹提升60%",icon="",},
[1311]={id=1311,heroName="玄机",range=7,position=0,nature=0,num={{14,1500,0},{15,3000,1}},name="玉有瑕玷",description="设施内所有门客的风度右降，但运筹左升15%",icon="",},
[1411]={id=1411,heroName="许诗葵",range=2,position=0,nature=0,num={{13,3000,1}},name="保元益气",description="许诗葵左方以及右方的一位门客，气魄提升30%",icon="",},
[1511]={id=1511,heroName="慕青丝",range=5,position=0,nature=0,num={{16,6000,1}},name="通心",description="慕青丝左方一位门客，反应提升60%",icon="",},
[1611]={id=1611,heroName="秦汉真",range=3,position=0,nature=0,num={{14,6000,1}},name="抱诚守真",description="秦汉真右方一位门客，风度提升60%",icon="",},
[1711]={id=1711,heroName="白栩",range=7,position=0,nature=0,num={{16,1500,0},{13,3000,1}},name="如雷",description="设施内所有门客的反应右降，但气魄提升15%",icon="",},
[1811]={id=1811,heroName="楚喻",range=4,position=0,nature=0,num={{15,3000,1}},name="希声",description="楚瑜右方的两位门客，运筹提升30%",icon="",},
[1911]={id=1911,heroName="蛇姬",range=6,position=0,nature=0,num={{13,3000,1}},name="萃棘",description="蛇姬左方的两位门客，气魄提升30%",icon="",},
[2011]={id=2011,heroName="凤来仪",range=2,position=0,nature=0,num={{13,1500,1},{14,1500,1},{15,1500,1},{16,1500,1}},name="孤诣",description="凤来仪左方以及右方的一位门客，各项属性提升15%",icon="",},
[2111]={id=2111,heroName="何似雪",range=1,position=2,nature=0,num={{14,6000,1}},name="沃雪",description="当何凌雪处于2号位时，自身风度提升60%",icon="",},
[2211]={id=2211,heroName="星无涯",range=9,position=0,nature=0,num={{13,1000,1},{14,1000,1},{15,1000,1},{16,1000,1}},name="神机兆于动",description="设施内除星无涯以外，每增加一名门客，星无涯自身的各项属性提升10%",icon="",},
[2311]={id=2311,heroName="月无夜",range=1,position=1,nature=0,num={{13,3000,1},{14,3000,1},{15,3000,1},{16,3000,1}},name="阐幽",description="当月无夜担任领工时，自身各项属性提升30%",icon="",},
[2411]={id=2411,heroName="泷",range=1,position=2,nature=0,num={{14,6000,1}},name="潜移暗化",description="当泷处于2号位时，自身风度提升60%",icon="",},
[2511]={id=2511,heroName="叶非天",range=1,position=3,nature=0,num={{13,3000,1},{14,3000,1},{15,3000,1},{16,3000,1}},name="就日瞻云",description="当叶非天处于3号位时，自身各项属性提升30%",icon="",},
[2611]={id=2611,heroName="沙莎",range=1,position=3,nature=0,num={{15,6000,1}},name="披沙拣金",description="当沙莎处于3号位时，自身运筹提升60%",icon="",},
[2711]={id=2711,heroName="叶隆",range=1,position=4,nature=0,num={{13,3000,1},{14,3000,1},{15,3000,1},{16,3000,1}},name="驭人",description="当叶隆处于4号位时，各项属性提升30%",icon="",},
[2811]={id=2811,heroName="何凌霄",range=7,position=0,nature=0,num={{13,1500,0},{15,3000,1}},name="蕙心",description="设施内所有角色的气魄右降，但运筹左升15%",icon="",},
[2911]={id=2911,heroName="何凝霜",range=4,position=0,nature=0,num={{13,1500,1},{14,1500,1},{15,1500,1},{16,1500,1}},name="纨质",description="何凌霜右方的两位门客，各项属性提升15%",icon="",},
[3011]={id=3011,heroName="都阿桃",range=9,position=0,nature=0,num={{13,1000,1},{14,1000,1},{15,1000,1},{16,1000,1}},name="灼灼其华",description="设施内除都阿桃以外，每增加一名门客，都阿桃自身各项属性提升10%",icon="",},
[3111]={id=3111,heroName="重鹤",range=1,position=1,nature=0,num={{13,3000,1},{14,3000,1},{15,3000,1},{16,3000,1}},name="成算在心",description="当重鹤担任领工时，自身各项属性提升30%",icon="",},
[3211]={id=3211,heroName="凤还朝",range=1,position=4,nature=0,num={{13,3000,1},{14,3000,1},{15,3000,1},{16,3000,1}},name="筹谋",description="当凤还朝处于4号位时，自身各项属性提升30%",icon="",},
[3311]={id=3311,heroName="鹿茵",range=6,position=0,nature=0,num={{13,1500,1},{14,1500,1},{15,1500,1},{16,1500,1}},name="无虞",description="鹿茵左方的两位门客，各项属性提升15%",icon="",},

}
local empty_table = {}
local default_value = {
    heroName = "苒苒",
range = 2,
position = 0,
nature = 0,
num = {{13,1500,1},{14,1500,1},{15,1500,1},{16,1500,1}},
name = "大快朵颐！",
description = "苒苒左方以及右方的一位门客，各项属性提升15%",
icon = "",

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
for _, v in pairs(talentBusiness) do
    setmetatable(v, metatable)
end
 
return talentBusiness
