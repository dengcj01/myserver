--keys:id|showEquipCnt|shopEnterProb|
local shopEnter={
[1]={id=1,showEquipCnt=0,shopEnterProb=0.4,},
[2]={id=2,showEquipCnt=1,shopEnterProb=0.6,},
[3]={id=3,showEquipCnt=2,shopEnterProb=0.65,},
[4]={id=4,showEquipCnt=3,shopEnterProb=0.7,},
[5]={id=5,showEquipCnt=4,shopEnterProb=0.75,},
[6]={id=6,showEquipCnt=5,shopEnterProb=0.8,},
[7]={id=7,showEquipCnt=6,shopEnterProb=0.85,},
[8]={id=8,showEquipCnt=7,shopEnterProb=0.9,},
[9]={id=9,showEquipCnt=8,shopEnterProb=0.95,},
[10]={id=10,showEquipCnt=9,shopEnterProb=0.95,},
[11]={id=11,showEquipCnt=10,shopEnterProb=0.95,},
[12]={id=12,showEquipCnt=11,shopEnterProb=0.95,},
[13]={id=13,showEquipCnt=12,shopEnterProb=0.95,},
[14]={id=14,showEquipCnt=13,shopEnterProb=0.95,},
[15]={id=15,showEquipCnt=14,shopEnterProb=0.95,},
[16]={id=16,showEquipCnt=15,shopEnterProb=0.95,},
[17]={id=17,showEquipCnt=16,shopEnterProb=0.95,},

}

local default_value = {
    showEquipCnt = 0,
shopEnterProb = 0.4,

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
for _, v in pairs(shopEnter) do
    setmetatable(v, metatable)
end
 
return shopEnter
