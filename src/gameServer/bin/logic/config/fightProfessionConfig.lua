--keys:id|name|typeIcon|icon|descr|type|
local fightProfessionConfig={
[1]={id=1,name="急羽",typeIcon="js_tipsjingong",icon="jiyu",descr="输出型职业，擅长长时间战斗，持续性造成伤害。",type={1,1},},
[2]={id=2,name="暗刑",typeIcon="js_tipsjingong",icon="anxing",descr="输出型职业，可于开场时爆发输出，造成大量伤害。",type={1,2},},
[3]={id=3,name="龙城",typeIcon="js_tipsfangyu",icon="longcheng",descr="防御型职业，为全队承担伤害。",type={1,3},},
[4]={id=4,name="破阵",typeIcon="js_tipsfangyu",icon="pozhen",descr="防御型职业，兼顾输出与承伤。",type={1,4},},
[5]={id=5,name="御法",typeIcon="js_tipsfuzhu",icon="yufa",descr="辅助型职业，擅长长时间战斗，造成友方增益或敌方减益效果。",type={1,5},},
[6]={id=6,name="司命",typeIcon="js_tipsfuzhu",icon="siming",descr="辅助型职业，可于开场时爆发，造成友方增益或敌方减益效果。",type={1,6},},
[7]={id=7,name="利刃",typeIcon="js_tipsjingong",icon="jiyu",descr="该武器类型的持有者击破目标时，对目标附加持续两回合的割伤效果，在自身行动时触发伤害。",type={2,1},},
[8]={id=8,name="重具",typeIcon="js_tipsjingong",icon="anxing",descr="该武器类型的持有者击破目标时，对目标附加持续两回合的钝伤效果，在自身行动时触发伤害，钝伤最多可叠加至5层。",type={2,2},},
[9]={id=9,name="远程",typeIcon="js_tipsfangyu",icon="longcheng",descr="该武器类型的持有者击破目标时，对目标附加持续两回合的箭伤效果，在自身行动时触发效果结算，造成目标速度降低。",type={2,3},},
[10]={id=10,name="奇兵",typeIcon="js_tipsfangyu",icon="pozhen",descr="该武器类型的持有者击破目标时，对目标附加持续两回合的内伤效果，在自身行动时触发效果结算，造成目标攻击降低。",type={2,4},},

}
local empty_table = {}
local default_value = {
    name = "急羽",
typeIcon = "js_tipsjingong",
icon = "jiyu",
descr = "输出型职业，擅长长时间战斗，持续性造成伤害。",
type = {1,1},

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
for _, v in pairs(fightProfessionConfig) do
    setmetatable(v, metatable)
end
 
return fightProfessionConfig
