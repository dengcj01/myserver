--keys:id|name_langId|description|needNumber|attribute|skillId|
local equipSuit={
[1]={id=1,name_langId="苍龙",description={"二件套：提升穿戴者【6%】攻击力。","四件套：战斗开始时，提升穿戴者【2点】速度和【2%】攻击力。"},needNumber={2,4},attribute={{103,600}},skillId={{2,0},{4,700101}},},
[2]={id=2,name_langId="旋龟",description={"二件套：提升穿戴者【9%】防御力。","四件套：战斗开始时，使穿戴者获得等同于自身【6%】生命值的护盾。"},needNumber={2,4},attribute={{104,900}},skillId={{2,0},{4,700102}},},
[3]={id=3,name_langId="石犀",description={"二件套：提升穿戴者【8%】生命。","四件套：战斗开始时，提升穿戴者基础生命值的【8%】的攻击力。"},needNumber={2,4},attribute={{102,800}},skillId={{2,0},{4,700103}},},
[4]={id=4,name_langId="青鸾",description={"二件套：提高穿戴者【6.4%】治疗量。","四件套：战斗开始时，我方立刻获得1点战技点。"},needNumber={2,4},attribute={{10,640}},skillId={{2,0},{4,700104}},},
[5]={id=5,name_langId="玄狐",description={"二件套：提升穿戴者【10%】攻击力。","四件套：战斗中穿戴者每次出手后，自身提高【2.5%】攻击力，最多可叠加5层。"},needNumber={2,4},attribute={{103,1000}},skillId={{2,0},{4,700105}},},
[6]={id=6,name_langId="夔牛",description={"二件套：提升穿戴者【15%】防御力。","四件套：战斗开始时，提升穿戴者【35%】基础防御力的攻击值。"},needNumber={2,4},attribute={{104,1500}},skillId={{2,0},{4,700106}},},
[7]={id=7,name_langId="银狼",description={"二件套：提升穿戴者【12%】生命值。","四件套：穿戴者生命百分比低于【50%】时，每损失【15%】最大生命值，提升穿戴者【5%】攻击力，最多提升【15%】。"},needNumber={2,4},attribute={{102,1200}},skillId={{2,0},{4,700107}},},
[8]={id=8,name_langId="云鹤",description={"二件套：提高穿戴者【9.6%】治疗效果。","四件套：穿戴者释放普攻后，增加我方全体【3.6%】攻击力，效果持续2回合。"},needNumber={2},attribute={{10,960}},skillId={{2,0},{4,700108}},},
[1001]={id=1001,name_langId="天禄",description={"二件套：提升穿戴者【6%】生命值。穿戴者生命百分比高于【50%】时，自身提升【7.5%】攻击力。"},needNumber={2},attribute={{102,600}},skillId={{2,700201}},},
[1002]={id=1002,name_langId="麒麟",description={"二件套：提升穿戴者【9%】防御力，穿戴者自身拥有护盾时，暴击率提升【2.7%】，暴击伤害提升【3.6%】。"},needNumber={2},attribute={{104,900}},skillId={{2,700202}},},
[1003]={id=1003,name_langId="三足乌",description={"二件套：提升穿戴者【8%】攻击力。战斗开始时，扣除自身【15%】生命值，并提升【9%】暴击率。"},needNumber={2},attribute={{103,800}},skillId={{2,700203}},},
[1004]={id=1004,name_langId="烛阴",description={"二件套：提高穿戴者【4.8%】暴击率，每次暴击时，提升【8%】攻击力，持续2回合。"},needNumber={2},attribute={{7,480}},skillId={{2,700204}},},
[1005]={id=1005,name_langId="腾蛇",description={"二件套：提升穿戴者【12%】暴击伤害。若暴击伤害高于【200%】，则自身暴击率额外提高【7.5%】。"},needNumber={2},attribute={{8,1200}},skillId={{2,700205}},},
[1006]={id=1006,name_langId="屏翳",description={"二件套：提升【10%】效果命中。若穿戴者效果命中大于【20%】，则在场队友攻击力均提升【2%】；若穿戴者效果命中大于【40%】，则在场队友攻击力均提升【4%】。"},needNumber={2},attribute={{11,1000}},skillId={{2,700206}},},
[1007]={id=1007,name_langId="鸿鹄",description={"二件套：提升【12%】效果抵抗。若穿戴者效果抵抗大于【20%】，则在场队友防御力提升【3.6%】；若穿戴者效果抵抗大于【40%】，则在场队友防御力提升【7.2%】。"},needNumber={2},attribute={{12,1200}},skillId={{2,700207}},},
[1008]={id=1008,name_langId="朱雀",description={"二件套：造成的伤害提升【9.6%】。穿戴者的生命值大于基础生命值的【140%】时，自身暴击率额外提升【9%】。"},needNumber={2},attribute={{51,960}},skillId={{2,700208}},},

}
local empty_table = {}
local default_value = {
    name_langId = "苍龙",
description = {"二件套：提升穿戴者【6%】攻击力。","四件套：战斗开始时，提升穿戴者【2点】速度和【2%】攻击力。"},
needNumber = {2,4},
attribute = {{103,600}},
skillId = {{2,0},{4,700101}},

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
for _, v in pairs(equipSuit) do
    setmetatable(v, metatable)
end
 
return equipSuit
