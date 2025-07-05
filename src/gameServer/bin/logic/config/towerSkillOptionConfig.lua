--keys:id|skillId|shopBuffCost|limit|icon|name|description|
local towerSkillOptionConfig={
[10001]={id=10001,skillId={100001},shopBuffCost={3,11,10},limit={{1,2}},icon="icon_attack_yelong",name="光速者",description="战斗开始时，提升穿戴者【2点】速度和【4%%】攻击力",},
[10002]={id=10002,skillId={100002},shopBuffCost={3,11,10},limit={{1,3}},icon="icon_skill_yelong",name="盾构",description="战斗开始时，使穿戴者获得一个等同于自身【8%%】生命值的护盾",},
[10003]={id=10003,skillId={100003},shopBuffCost={3,11,10},limit={{1,4}},icon="icon_passive_yelong",name="肉盾",description="战斗开始时，根据穿戴者基础生命值的【9%%】提升穿戴者攻击力",},
[10004]={id=10004,skillId={100004},shopBuffCost={3,11,50},limit={{2,5}},icon="icon_attack_yelong",name="多你一点",description="战斗开始时，我方立刻获得1点战技点",},
[10005]={id=10005,skillId={100005},shopBuffCost={3,11,10},limit={{2,6}},icon="icon_skill_yelong",name="攻击叠",description="战斗中穿戴者每次出手后，自身提高【3%%】攻击力，最多可叠加5层",},
[10006]={id=10006,skillId={100006},shopBuffCost={3,11,10},limit={},icon="icon_passive_yelong",name="高防用户",description="战斗开始时，根据穿戴者基础防御力的【41%%】提升穿戴者攻击力",},
[10007]={id=10007,skillId={100007},shopBuffCost={3,11,50},limit={{1,2}},icon="icon_attack_xushikui",name="残雪越墙",description="穿戴者生命百分比低于【50%%】时，每损失【30%%】最大生命值，提升穿戴者【7%%】攻击力，最多提升【21%%】",},
[10008]={id=10008,skillId={100008},shopBuffCost={3,11,60},limit={{1,2}},icon="icon_skill_xushikui",name="普攻增幅",description="穿戴者释放普攻后，增加我方全体【4.2%%】攻击力，持续2回合",},
[10009]={id=10009,skillId={100009},shopBuffCost={3,11,20},limit={{1,2}},icon="icon_passive_xushikui",name="血高攻高",description="穿戴者生命百分比高于【50%%】时，自身提升【10%%】攻击力",},
[10010]={id=10010,skillId={100010},shopBuffCost={3,11,100},limit={},icon="icon_attack_xushikui",name="有盾高爆",description="穿戴者自身拥有护盾时，暴击率提升【3%%】",},
[10011]={id=10011,skillId={100011},shopBuffCost={3,11,100},limit={},icon="icon_skill_xushikui",name="扣血高爆",description="穿戴者战斗开始时扣除自身【15%%】生命值，并提升【9%%】暴击率",},
[10012]={id=10012,skillId={100012},shopBuffCost={3,11,100},limit={{2,5}},icon="icon_passive_xushikui",name="暴击加攻",description="战斗中穿戴者暴击时，提升【10%%】攻击力，持续2回合",},
[10013]={id=10013,skillId={100013},shopBuffCost={3,11,60},limit={{2,5}},icon="icon_attack_xushikui",name="爆爆爆！",description="若穿戴者暴击伤害大于【200%%】，则自身暴击率提高【9%%】",},
[10014]={id=10014,skillId={100014},shopBuffCost={3,11,20},limit={{2,5}},icon="icon_skill_xushikui",name="不会起名",description="若穿戴者效果命中大于【20%%】，则全体队员攻击力提升【2.4%%】；若穿戴者效果命中大于【40%%】时，则全体队员攻击力提升【4.8%%】",},
[10015]={id=10015,skillId={100015},shopBuffCost={3,11,60},limit={},icon="icon_passive_xushikui",name="不会起名2",description="若穿戴者效果抵抗大于【20%%】，则全体队员防御力提升【4.2%%】；若穿戴者效果抵抗大于【40%%】时，则全体队员防御力提升【8.4%%】",},
[10016]={id=10016,skillId={100016},shopBuffCost={3,11,20},limit={},icon="icon_attack_xushikui",name="不会起名3",description="穿戴者额外生命百分比加成大于【40%%】时，自身暴击率提升【10%%】",},

}
local empty_table = {}
local default_value = {
    skillId = {100001},
shopBuffCost = {3,11,10},
limit = {{1,2}},
icon = "icon_attack_yelong",
name = "光速者",
description = "战斗开始时，提升穿戴者【2点】速度和【4%%】攻击力",

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
for _, v in pairs(towerSkillOptionConfig) do
    setmetatable(v, metatable)
end
 
return towerSkillOptionConfig
