--keys:id|name|description|room|directCustomer|waitingTime|talk|queuing|discountEnergy|buyEquipment|highAttribute|moreAttribute|gather|attributeUp|professionType|genresType|effectSkill|recovertTime|
local furnitureTalent={
[1]={id=1,name="玉面狸神龛",description="增加主动购买型客人比例{0}%",room=1,directCustomer={100,200,300,400,500,600,700,800,900,1000},waitingTime={},talk={},queuing={},discountEnergy={},buyEquipment={},highAttribute={},moreAttribute={},gather={},attributeUp={},professionType={},genresType={},effectSkill={},recovertTime={},},
[2]={id=2,name="白兔花灯（没有该功能 因此摆件效果可以先不做）",description="增加公主需求等待时间{0}秒",room=1,directCustomer={},waitingTime={100,200,300,400,500,600,700,800,900,1000},talk={},queuing={},discountEnergy={},buyEquipment={},highAttribute={},moreAttribute={},gather={},attributeUp={},professionType={},genresType={},effectSkill={},recovertTime={},},
[3]={id=3,name="阿黄蹲蹲",description="提升闲聊成功概率{0}%",room=2,directCustomer={},waitingTime={},talk={100,200,300,400,500,600,700,800,900,1000},queuing={},discountEnergy={},buyEquipment={},highAttribute={},moreAttribute={},gather={},attributeUp={},professionType={},genresType={},effectSkill={},recovertTime={},},
[4]={id=4,name="阿桃趴趴（没有该功能 因此摆件效果可以先不做）",description="提升可以排队买单的人数{0}人",room=2,directCustomer={},waitingTime={},talk={},queuing={1,2,3,4,5,6,7,8,9,10},discountEnergy={},buyEquipment={},highAttribute={},moreAttribute={},gather={},attributeUp={},professionType={},genresType={},effectSkill={},recovertTime={},},
[5]={id=5,name="小啜香茶",description="提供建议需要消耗的满意度减少{0}%（最底满意度消耗为1）",room=3,directCustomer={},waitingTime={},talk={},queuing={},discountEnergy={1,2,3,4,5,6,7,8,9,10},buyEquipment={},highAttribute={},moreAttribute={},gather={},attributeUp={},professionType={},genresType={},effectSkill={},recovertTime={},},
[6]={id=6,name="眠眠（没有该功能 因此摆件效果可以先不做）",description="提升购买高阶商品的概率",room=3,directCustomer={},waitingTime={},talk={},queuing={},discountEnergy={},buyEquipment={100,200,300,400,500,600,700,800,900,1000},highAttribute={},moreAttribute={},gather={},attributeUp={},professionType={},genresType={},effectSkill={},recovertTime={},},
[7]={id=7,name="剑门细雨",description="制造武器绝品（橙装）概率提升{0}%",room=4,directCustomer={},waitingTime={},talk={},queuing={},discountEnergy={},buyEquipment={},highAttribute={{1,100},{1,200},{1,300},{1,400},{1,500},{1,600},{1,700},{1,800},{1,900},{1,1000}},moreAttribute={},gather={},attributeUp={},professionType={},genresType={},effectSkill={},recovertTime={},},
[8]={id=8,name="燕栖剑谱",description="制造武器初始词条满数量概率提高{0}%",room=4,directCustomer={},waitingTime={},talk={},queuing={},discountEnergy={},buyEquipment={},highAttribute={},moreAttribute={{1,100},{1,200},{1,300},{1,400},{1,500},{1,600},{1,700},{1,800},{1,900},{1,1000}},gather={},attributeUp={},professionType={},genresType={},effectSkill={},recovertTime={},},
[9]={id=9,name="龟鹤遐龄",description="制造防具绝品（橙装）概率提升{0}%",room=5,directCustomer={},waitingTime={},talk={},queuing={},discountEnergy={},buyEquipment={},highAttribute={{2,100},{2,200},{2,300},{2,400},{2,500},{2,600},{2,700},{2,800},{2,900},{2,1000}},moreAttribute={},gather={},attributeUp={},professionType={},genresType={},effectSkill={},recovertTime={},},
[10]={id=10,name="龙众",description="制造防具初始词条满数量概率提高{0}%",room=5,directCustomer={},waitingTime={},talk={},queuing={},discountEnergy={},buyEquipment={},highAttribute={},moreAttribute={{2,100},{2,200},{2,300},{2,400},{2,500},{2,600},{2,700},{2,800},{2,900},{2,1000}},gather={},attributeUp={},professionType={},genresType={},effectSkill={},recovertTime={},},
[11]={id=11,name="三足金蟾",description="制造饰品绝品（橙装）概率提升{0}%",room=6,directCustomer={},waitingTime={},talk={},queuing={},discountEnergy={},buyEquipment={},highAttribute={{3,100},{3,200},{3,300},{3,400},{3,500},{3,600},{3,700},{3,800},{3,900},{3,1000}},moreAttribute={},gather={},attributeUp={},professionType={},genresType={},effectSkill={},recovertTime={},},
[12]={id=12,name="瑞兽辟邪",description="制造饰品初始词条满数量概率提高{0}%",room=6,directCustomer={},waitingTime={},talk={},queuing={},discountEnergy={},buyEquipment={},highAttribute={},moreAttribute={{3,100},{3,200},{3,300},{3,400},{3,500},{3,600},{3,700},{3,800},{3,900},{3,1000}},gather={},attributeUp={},professionType={},genresType={},effectSkill={},recovertTime={},},
[13]={id=13,name="衡器",description="矿石产量增加{0}%",room=7,directCustomer={},waitingTime={},talk={},queuing={},discountEnergy={},buyEquipment={},highAttribute={},moreAttribute={},gather={{2001,100},{2001,200},{2001,300},{2001,400},{2001,500},{2001,600},{2001,700},{2001,800},{2001,900},{2001,1000}},attributeUp={},professionType={},genresType={},effectSkill={},recovertTime={},},
[14]={id=14,name="百草尝",description="结草产量大幅增加{0}%",room=7,directCustomer={},waitingTime={},talk={},queuing={},discountEnergy={},buyEquipment={},highAttribute={},moreAttribute={},gather={{2004,200},{2004,400},{2004,600},{2004,800},{2004,1000},{2004,1200},{2004,1400},{2004,1600},{2004,1800},{2004,2000}},attributeUp={},professionType={},genresType={},effectSkill={},recovertTime={},},
[15]={id=15,name="翠玉孤飞",description="生命提升{0}%，攻击提升{1}%，防御提升{2}%，{3}",room=8,directCustomer={},waitingTime={},talk={},queuing={},discountEnergy={},buyEquipment={},highAttribute={},moreAttribute={},gather={},attributeUp={{{2,54},{3,36},{4,36}},{{2,108},{3,72},{4,72}},{{2,162},{3,108},{4,108}},{{2,216},{3,144},{4,144}},{{2,270},{3,180},{4,180}},{{2,324},{3,216},{4,216}},{{2,378},{3,252},{4,252}},{{2,432},{3,288},{4,288}},{{2,486},{3,324},{4,324}},{{2,540},{3,360},{4,360}}},professionType={1},genresType={1,2,3,4},effectSkill={800101},recovertTime={},},
[16]={id=16,name="一捻红",description="生命提升{0}%，攻击提升{1}%，防御提升{2}%，{3}",room=8,directCustomer={},waitingTime={},talk={},queuing={},discountEnergy={},buyEquipment={},highAttribute={},moreAttribute={},gather={},attributeUp={{{2,54},{3,36},{4,36}},{{2,108},{3,72},{4,72}},{{2,162},{3,108},{4,108}},{{2,216},{3,144},{4,144}},{{2,270},{3,180},{4,180}},{{2,324},{3,216},{4,216}},{{2,378},{3,252},{4,252}},{{2,432},{3,288},{4,288}},{{2,486},{3,324},{4,324}},{{2,540},{3,360},{4,360}}},professionType={2},genresType={1,2,3,4},effectSkill={800201},recovertTime={},},
[17]={id=17,name="灵寿子",description="生命提升{0}%，攻击提升{1}%，防御提升{2}%，{3}",room=8,directCustomer={},waitingTime={},talk={},queuing={},discountEnergy={},buyEquipment={},highAttribute={},moreAttribute={},gather={},attributeUp={{{2,54},{3,36},{4,36}},{{2,108},{3,72},{4,72}},{{2,162},{3,108},{4,108}},{{2,216},{3,144},{4,144}},{{2,270},{3,180},{4,180}},{{2,324},{3,216},{4,216}},{{2,378},{3,252},{4,252}},{{2,432},{3,288},{4,288}},{{2,486},{3,324},{4,324}},{{2,540},{3,360},{4,360}}},professionType={3},genresType={1,2,3,4},effectSkill={800301},recovertTime={},},
[18]={id=18,name="兔兔沙包",description="生命提升{0}%，攻击提升{1}%，防御提升{2}%，{3}",room=8,directCustomer={},waitingTime={},talk={},queuing={},discountEnergy={},buyEquipment={},highAttribute={},moreAttribute={},gather={},attributeUp={{{2,54},{3,36},{4,36}},{{2,108},{3,72},{4,72}},{{2,162},{3,108},{4,108}},{{2,216},{3,144},{4,144}},{{2,270},{3,180},{4,180}},{{2,324},{3,216},{4,216}},{{2,378},{3,252},{4,252}},{{2,432},{3,288},{4,288}},{{2,486},{3,324},{4,324}},{{2,540},{3,360},{4,360}}},professionType={4},genresType={1,2,3,4},effectSkill={800401},recovertTime={},},
[19]={id=19,name="璎珞藤",description="生命提升{0}%，攻击提升{1}%，防御提升{2}%，{3}",room=8,directCustomer={},waitingTime={},talk={},queuing={},discountEnergy={},buyEquipment={},highAttribute={},moreAttribute={},gather={},attributeUp={{{2,54},{3,36},{4,36}},{{2,108},{3,72},{4,72}},{{2,162},{3,108},{4,108}},{{2,216},{3,144},{4,144}},{{2,270},{3,180},{4,180}},{{2,324},{3,216},{4,216}},{{2,378},{3,252},{4,252}},{{2,432},{3,288},{4,288}},{{2,486},{3,324},{4,324}},{{2,540},{3,360},{4,360}}},professionType={5},genresType={1,2,3,4},effectSkill={800501},recovertTime={},},
[20]={id=20,name="望舒荷",description="生命提升{0}%，攻击提升{1}%，防御提升{2}%，{3}",room=8,directCustomer={},waitingTime={},talk={},queuing={},discountEnergy={},buyEquipment={},highAttribute={},moreAttribute={},gather={},attributeUp={{{2,54},{3,36},{4,36}},{{2,108},{3,72},{4,72}},{{2,162},{3,108},{4,108}},{{2,216},{3,144},{4,144}},{{2,270},{3,180},{4,180}},{{2,324},{3,216},{4,216}},{{2,378},{3,252},{4,252}},{{2,432},{3,288},{4,288}},{{2,486},{3,324},{4,324}},{{2,540},{3,360},{4,360}}},professionType={6},genresType={1,2,3,4},effectSkill={800601},recovertTime={},},
[21]={id=21,name="木心石腹",description="生命提升{0}%，攻击提升{1}%，防御提升{2}%，{3}",room=8,directCustomer={},waitingTime={},talk={},queuing={},discountEnergy={},buyEquipment={},highAttribute={},moreAttribute={},gather={},attributeUp={{{2,54},{3,36},{4,36}},{{2,108},{3,72},{4,72}},{{2,162},{3,108},{4,108}},{{2,216},{3,144},{4,144}},{{2,270},{3,180},{4,180}},{{2,324},{3,216},{4,216}},{{2,378},{3,252},{4,252}},{{2,432},{3,288},{4,288}},{{2,486},{3,324},{4,324}},{{2,540},{3,360},{4,360}}},professionType={1,2,3,4,5,6},genresType={1,2,3,4},effectSkill={800701},recovertTime={},},

}
local empty_table = {}
local default_value = {
    name = "玉面狸神龛",
description = "增加主动购买型客人比例{0}%",
room = 1,
directCustomer = {100,200,300,400,500,600,700,800,900,1000},
waitingTime = {},
talk = {},
queuing = {},
discountEnergy = {},
buyEquipment = {},
highAttribute = {},
moreAttribute = {},
gather = {},
attributeUp = empty_table,
professionType = {},
genresType = {},
effectSkill = {},
recovertTime = {},

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
for _, v in pairs(furnitureTalent) do
    setmetatable(v, metatable)
end
 
return furnitureTalent
