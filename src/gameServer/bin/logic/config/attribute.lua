--keys:id|fakeName|name|type|sort|show|ratio|power|depend|icon|dec|icon2|
local attribute={

[2]={id=2,fakeName="生命",name="hp",type=1,sort=1,show=1,ratio=0,power=2,depend=0,icon="js_shengming",dec="生命值上限",icon2="js_shengming02",},
[3]={id=3,fakeName="攻击",name="atk",type=1,sort=2,show=1,ratio=0,power=10,depend=0,icon="js_gongji",dec="攻击",icon2="js_gongji02",},
[4]={id=4,fakeName="防御",name="def",type=1,sort=3,show=1,ratio=0,power=5,depend=0,icon="js_fangyu",dec="防御",icon2="js_fangyu02",},
[5]={id=5,fakeName="速度",name="dex",type=1,sort=4,show=1,ratio=0,power=12,depend=0,icon="js_minjie",dec="影响角色行动先后",icon2="js_minjie02",},
[6]={id=6,fakeName="闪避",name="eva",type=2,sort=5,show=1,ratio=1,power=24,depend=0,icon="js_shanbilü",dec="闪避率",icon2="js_shanbilü02",},

[8]={id=8,fakeName="暴伤",name="criD",type=1,sort=7,show=1,ratio=1,power=0.6,depend=0,icon="js_baojilü",dec="暴击伤害加成比例",icon2="js_baojilü02",},
[9]={id=9,fakeName="击破",name="brk",type=2,sort=8,show=1,ratio=1,power=12,depend=0,icon="js_baojilü",dec="击破伤害加成比例",icon2="js_baojilü02",},
[10]={id=10,fakeName="治疗加成",name="trt",type=2,sort=9,show=1,ratio=1,power=12,depend=0,icon="js_mingzhonglü",dec="治疗加成比例",icon2="js_baojilü02",},
[11]={id=11,fakeName="效果命中",name="bufA",type=2,sort=10,show=1,ratio=1,power=0,depend=0,icon="js_mingzhonglü",dec="效果命中概率",icon2="js_baojilü02",},
[12]={id=12,fakeName="效果抵抗",name="bufE",type=2,sort=11,show=1,ratio=1,power=0,depend=0,icon="js_kangbaolü",dec="效果抵抗概率",icon2="js_baojilü02",},
[13]={id=13,fakeName="气魄",name="boldness",type=1,sort=12,show=1,ratio=0,power=0,depend=0,icon="qipo",dec="人若有气魄，方做得事成。",icon2="qipo",},
[14]={id=14,fakeName="风度",name="demeanor",type=1,sort=13,show=1,ratio=0,power=0,depend=0,icon="fengdu",dec="尘飞扬雅梵，风度引疏钟。",icon2="fengdu",},
[15]={id=15,fakeName="运筹",name="logistics",type=1,sort=14,show=1,ratio=0,power=0,depend=0,icon="yunchou",dec="运筹闲暇，何害推敲。",icon2="yunchou",},
[16]={id=16,fakeName="反应",name="react",type=1,sort=15,show=1,ratio=0,power=0,depend=0,icon="fanying",dec="急景流年真一箭。残雪声中，省识东风面。",icon2="fanying",},
[100]={id=100,fakeName="嘲讽",name="tau",type=0,sort=0,show=0,ratio=0,power=0,depend=0,icon="js_shengming",dec="",icon2="js_shengming02",},
[101]={id=101,fakeName="当前生命",name="hpNow_ra",type=0,sort=0,show=0,ratio=1,power=0,depend=1,icon="js_shengming",dec="",icon2="js_shengming02",},

[23]={id=23,fakeName="奇兵伤害",name="weku_fan",type=2,sort=23,show=1,ratio=1,power=12,depend=0,icon="js_qibing",dec="奇兵伤害提升比例",icon2="js_qibing02",},
[24]={id=24,fakeName="金伤害",name="weku_metal",type=2,sort=24,show=1,ratio=1,power=12,depend=0,icon="js_jin",dec="金伤害提升比例",icon2="js_jin02",},
[25]={id=25,fakeName="木伤害",name="weku_wood",type=2,sort=25,show=1,ratio=1,power=12,depend=0,icon="js_mu",dec="木伤害提升比例",icon2="js_mu02",},
[26]={id=26,fakeName="水伤害",name="weku_water",type=2,sort=26,show=1,ratio=1,power=12,depend=0,icon="js_shui",dec="水伤害提升比例",icon2="js_shui02",},
[27]={id=27,fakeName="火伤害",name="weku_fire",type=2,sort=27,show=1,ratio=1,power=12,depend=0,icon="js_huo",dec="火伤害提升比例",icon2="js_huo02",},
[28]={id=28,fakeName="土伤害",name="weku_earth",type=2,sort=28,show=1,ratio=1,power=12,depend=0,icon="js_tu",dec="土伤害提升比例",icon2="js_tu02",},
[30]={id=30,fakeName="利刃抵抗",name="wekd_swd",type=2,sort=30,show=1,ratio=1,power=24,depend=0,icon="js_qibing(fang)",dec="利刃抵抗提升比例",icon2="js_qibing(fang)02",},

[51]={id=51,fakeName="伤害提升",name="dmgUp",type=2,sort=51,show=0,ratio=1,power=0,depend=0,icon="js_baojilü02",dec="",icon2="js_baojilü02",},

[100002]={id=100002,fakeName="角色冲刺速度",name="speed",type=1,sort=100002,show=0,ratio=0,power=0,depend=0,icon="js_baojilü02",dec="",icon2="js_baojilü02",},

}

local default_value = {
    fakeName = "当前生命",
name = "hpNow",
type = 0,
sort = 0,
show = 0,
ratio = 0,
power = 0,
depend = 0,
icon = "",
dec = "",
icon2 = "",

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
for _, v in pairs(attribute) do
    setmetatable(v, metatable)
end
 
return attribute
