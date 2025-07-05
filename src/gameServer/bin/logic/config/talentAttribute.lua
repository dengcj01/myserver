--keys:id|attribute|attributeNum|icon|name|desc|
local talentAttribute={
[101]={id=101,attribute=102,attributeNum=500,icon="icon_attribute_shengming",name="生命",desc="生命上限提升%s",},
[102]={id=102,attribute=103,attributeNum=500,icon="icon_attribute_gongji",name="攻击",desc="攻击提升提升%s",},
[103]={id=103,attribute=104,attributeNum=750,icon="icon_attribute_fangyu",name="防御",desc="防御提升提升%s",},
[104]={id=104,attribute=7,attributeNum=300,icon="icon_attribute_baoji",name="暴击",desc="暴击率提升%s",},
[105]={id=105,attribute=8,attributeNum=600,icon="icon_attribute_baoji",name="暴伤",desc="暴击伤害提升%s",},
[106]={id=106,attribute=9,attributeNum=625,icon="icon_attribute_baoji",name="击破",desc="击破伤害提升%s",},
[107]={id=107,attribute=5,attributeNum=1,icon="icon_attribute_shanbi",name="速度",desc="速度提升%s",},
[108]={id=108,attribute=11,attributeNum=500,icon="icon_attribute_mingzhong",name="效果命中",desc="状态效果命中提升%s",},
[109]={id=109,attribute=12,attributeNum=500,icon="icon_attribute_dikang",name="效果抵抗",desc="状态效果抵抗提升%s",},
[110]={id=110,attribute=20,attributeNum=400,icon="icon_attribute_liren",name="利刃伤害",desc="利刃伤害提升%s",},
[111]={id=111,attribute=21,attributeNum=400,icon="icon_attribute_zhongju",name="重具伤害",desc="重具伤害提升%s",},
[112]={id=112,attribute=22,attributeNum=400,icon="icon_attribute_yuancheng",name="远程伤害",desc="远程伤害提升%s",},
[113]={id=113,attribute=23,attributeNum=400,icon="icon_attribute_qibing",name="奇兵伤害",desc="奇兵伤害提升%s",},
[114]={id=114,attribute=24,attributeNum=400,icon="icon_attribute_jin",name="金伤害",desc="金伤害提升%s",},
[115]={id=115,attribute=25,attributeNum=400,icon="icon_attribute_mu",name="木伤害",desc="木伤害提升%s",},
[116]={id=116,attribute=26,attributeNum=400,icon="icon_attribute_shui",name="水伤害",desc="水伤害提升%s",},
[117]={id=117,attribute=27,attributeNum=400,icon="icon_attribute_huo",name="火伤害",desc="火伤害提升%s",},
[118]={id=118,attribute=28,attributeNum=400,icon="icon_attribute_tu",name="土伤害",desc="土伤害提升%s",},
[119]={id=119,attribute=10,attributeNum=400,icon="icon_attribute_mingzhong",name="治疗加成",desc="治疗效果加成%s",},
[201]={id=201,attribute=102,attributeNum=600,icon="icon_attribute_shengming",name="生命",desc="生命上限提升%s",},
[202]={id=202,attribute=103,attributeNum=600,icon="icon_attribute_gongji",name="攻击",desc="攻击提升提升%s",},
[203]={id=203,attribute=104,attributeNum=900,icon="icon_attribute_fangyu",name="防御",desc="防御提升提升%s",},
[204]={id=204,attribute=7,attributeNum=360,icon="icon_attribute_baoji",name="暴击",desc="暴击率提升%s",},
[205]={id=205,attribute=8,attributeNum=720,icon="icon_attribute_baoji",name="暴伤",desc="暴击伤害提升%s",},
[206]={id=206,attribute=9,attributeNum=750,icon="icon_attribute_baoji",name="击破",desc="击破伤害提升%s",},
[207]={id=207,attribute=5,attributeNum=2,icon="icon_attribute_shanbi",name="速度",desc="速度提升%s",},
[208]={id=208,attribute=11,attributeNum=600,icon="icon_attribute_mingzhong",name="效果命中",desc="状态效果命中提升%s",},
[209]={id=209,attribute=12,attributeNum=600,icon="icon_attribute_dikang",name="效果抵抗",desc="状态效果抵抗提升%s",},
[210]={id=210,attribute=20,attributeNum=480,icon="icon_attribute_liren",name="利刃伤害",desc="利刃伤害提升%s",},
[211]={id=211,attribute=21,attributeNum=480,icon="icon_attribute_zhongju",name="重具伤害",desc="重具伤害提升%s",},
[212]={id=212,attribute=22,attributeNum=480,icon="icon_attribute_yuancheng",name="远程伤害",desc="远程伤害提升%s",},
[213]={id=213,attribute=23,attributeNum=480,icon="icon_attribute_qibing",name="奇兵伤害",desc="奇兵伤害提升%s",},
[214]={id=214,attribute=24,attributeNum=480,icon="icon_attribute_jin",name="金伤害",desc="金伤害提升%s",},
[215]={id=215,attribute=25,attributeNum=480,icon="icon_attribute_mu",name="木伤害",desc="木伤害提升%s",},
[216]={id=216,attribute=26,attributeNum=480,icon="icon_attribute_shui",name="水伤害",desc="水伤害提升%s",},
[217]={id=217,attribute=27,attributeNum=480,icon="icon_attribute_huo",name="火伤害",desc="火伤害提升%s",},
[218]={id=218,attribute=28,attributeNum=480,icon="icon_attribute_tu",name="土伤害",desc="土伤害提升%s",},
[219]={id=219,attribute=10,attributeNum=480,icon="icon_attribute_mingzhong",name="治疗加成",desc="治疗效果加成%s",},
[301]={id=301,attribute=102,attributeNum=800,icon="icon_attribute_shengming",name="生命",desc="生命上限提升%s",},
[302]={id=302,attribute=103,attributeNum=800,icon="icon_attribute_gongji",name="攻击",desc="攻击提升提升%s",},
[303]={id=303,attribute=104,attributeNum=1200,icon="icon_attribute_fangyu",name="防御",desc="防御提升提升%s",},
[304]={id=304,attribute=7,attributeNum=480,icon="icon_attribute_baoji",name="暴击",desc="暴击率提升%s",},
[305]={id=305,attribute=8,attributeNum=960,icon="icon_attribute_baoji",name="暴伤",desc="暴击伤害提升%s",},
[306]={id=306,attribute=9,attributeNum=1000,icon="icon_attribute_baoji",name="击破",desc="击破伤害提升%s",},
[307]={id=307,attribute=5,attributeNum=3,icon="icon_attribute_shanbi",name="速度",desc="速度提升%s",},
[308]={id=308,attribute=11,attributeNum=800,icon="icon_attribute_mingzhong",name="效果命中",desc="状态效果命中提升%s",},
[309]={id=309,attribute=12,attributeNum=800,icon="icon_attribute_dikang",name="效果抵抗",desc="状态效果抵抗提升%s",},
[310]={id=310,attribute=20,attributeNum=640,icon="icon_attribute_liren",name="利刃伤害",desc="利刃伤害提升%s",},
[311]={id=311,attribute=21,attributeNum=640,icon="icon_attribute_zhongju",name="重具伤害",desc="重具伤害提升%s",},
[312]={id=312,attribute=22,attributeNum=640,icon="icon_attribute_yuancheng",name="远程伤害",desc="远程伤害提升%s",},
[313]={id=313,attribute=23,attributeNum=640,icon="icon_attribute_qibing",name="奇兵伤害",desc="奇兵伤害提升%s",},
[314]={id=314,attribute=24,attributeNum=640,icon="icon_attribute_jin",name="金伤害",desc="金伤害提升%s",},
[315]={id=315,attribute=25,attributeNum=640,icon="icon_attribute_mu",name="木伤害",desc="木伤害提升%s",},
[316]={id=316,attribute=26,attributeNum=640,icon="icon_attribute_shui",name="水伤害",desc="水伤害提升%s",},
[317]={id=317,attribute=27,attributeNum=640,icon="icon_attribute_huo",name="火伤害",desc="火伤害提升%s",},
[318]={id=318,attribute=28,attributeNum=640,icon="icon_attribute_tu",name="土伤害",desc="土伤害提升%s",},
[319]={id=319,attribute=10,attributeNum=640,icon="icon_attribute_mingzhong",name="治疗加成",desc="治疗效果加成%s",},

}

local default_value = {
    attribute = 102,
attributeNum = 500,
icon = "icon_attribute_shengming",
name = "生命",
desc = "生命上限提升%s",

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
for _, v in pairs(talentAttribute) do
    setmetatable(v, metatable)
end
 
return talentAttribute
