--keys:id|name|type|openLevel|typeImage|typeBg|typeEffect|selectedIndex|startTime|endTime|upFurniture|upHero|showHero|cost|oneDropGroup|oneDropWeight|smallNum|smallDropGroup|smallDropWeight|probIncrStartNum|probIncrDropGroup|probIncrVal|middleNum|middleDropGroup|middleDropWeight|bigNum|bigDropGroup|bigDropWeight|firstDropGroup|firstDropWeight|firstDropNum|gachaMyselfNum|gachaMyself|firstDrop|recruitRule|gachaDesc|UPProbability|retItemId|bgPrefab|
local gacha={
[1]={id=1,name="新手卡池",type=1,openLevel=1,typeImage="kc_huodongjianyi01",typeBg="kc_xslihui",typeEffect={},selectedIndex=0,startTime={},endTime={},upFurniture={},upHero={},showHero={8},cost={5001,1},oneDropGroup={10001,10002,10003,10004,10005,10006},oneDropWeight={80,515,1500,6500,415,990},smallNum=10,smallDropGroup={10001,10002},smallDropWeight={80,9920},probIncrStartNum=60,probIncrDropGroup=10001,probIncrVal=1000,middleNum=0,middleDropGroup={},middleDropWeight={},bigNum=0,bigDropGroup={},bigDropWeight={},firstDropGroup={10103},firstDropWeight={100},firstDropNum=50,gachaMyselfNum=0,gachaMyself={},firstDrop=2,recruitRule="1、迎新福利：第50次祈灵时，必可获取一位天级门客。\n2、每进行十次祈灵，结果中必包含至少一位门客角色，若在达成十次祈灵前已获得了门客角色，则该进度重新开始计算。",gachaDesc="该祈灵为面向新玩家开放的特殊祈灵。",UPProbability=5000,retItemId={{3,13,20}},bgPrefab="shanhetiaotiao",},
[2]={id=2,name="通用卡池",type=2,openLevel=1,typeImage="kc_huodongjianyi02",typeBg="kc_tongyong",typeEffect={},selectedIndex=1,startTime={},endTime={},upFurniture={},upHero={},showHero={27,9,10,14,11},cost={5001,1},oneDropGroup={10010,10011,10012,10013,10014,10015},oneDropWeight={80,515,1500,6500,415,990},smallNum=10,smallDropGroup={10010,10011},smallDropWeight={80,9920},probIncrStartNum=60,probIncrDropGroup=10010,probIncrVal=1000,middleNum=70,middleDropGroup={10101},middleDropWeight={100},bigNum=0,bigDropGroup={},bigDropWeight={},firstDropGroup={},firstDropWeight={},firstDropNum=0,gachaMyselfNum=100,gachaMyself={4,5,8,10,22,27},firstDrop=0,recruitRule="1、累计祈灵60次后，每次祈灵增加10%的天级门客获取概率，累计祈灵70次后，必定获取天级门客。当获得天级门客后，保底计数随之清空。\n2、每进行十次祈灵，结果中必包含至少一位门客角色，若在达成十次祈灵前已获得了门客角色，则该进度重新开始计算。\n3、累计祈灵100次后，可以自选获得一位卡池内的天级门客。\n4、以上机制均互相计算进度，不互相干扰。",gachaDesc="该祈灵为永久性活动。",UPProbability=5000,retItemId={{3,13,20}},bgPrefab="shanhetiaotiao",},
[3]={id=3,name="限定卡池",type=3,openLevel=1,typeImage="kc_huodongjianyi03",typeBg="kc_xianding",typeEffect={},selectedIndex=2,startTime={2024,2,1,1,11,1},endTime={2025,2,7,17,0,0},upFurniture={},upHero={},showHero={7,30},cost={5001,1},oneDropGroup={10020,10021,10022,10023,10024,10025},oneDropWeight={80,515,1500,6500,415,990},smallNum=10,smallDropGroup={10020,10021},smallDropWeight={80,9920},probIncrStartNum=60,probIncrDropGroup=10020,probIncrVal=1000,middleNum=70,middleDropGroup={10102},middleDropWeight={100},bigNum=140,bigDropGroup={10104},bigDropWeight={100},firstDropGroup={},firstDropWeight={},firstDropNum=0,gachaMyselfNum=0,gachaMyself={},firstDrop=0,recruitRule="1、累计祈灵60次后，每次祈灵增加10%的天级门客获取概率。\n2、小保底机制：累计祈灵70次后，必定获取天级门客。当获得天级门客后，保底计数随之清空。\n3、大保底机制：累计祈灵140次后，必定获取本期限定天级门客。当获得限定门客后，保底计数随之清空（该计数与小保底各自计数）。\n4、保底机制轮换：获得天级门客后会触发保底轮换，触发后会让处于小保底阶段的玩家进入大保底阶段，处于大保底阶段的玩家进入小保底阶段。\n5、每进行十次祈灵，结果中必包含至少一位地级门客角色，若在达成十次祈灵前已获得了地级门客角色，则该进度重新开始计算。\n6、以上机制均互相计算进度，不互相干扰。",gachaDesc="该祈灵为限时活动。",UPProbability=5000,retItemId={{3,13,20}},bgPrefab="shanhetiaotiao",},

}
local empty_table = {}
local default_value = {
    name = "新手卡池",
type = 1,
openLevel = 1,
typeImage = "kc_huodongjianyi01",
typeBg = "kc_xslihui",
typeEffect = {},
selectedIndex = 0,
startTime = {},
endTime = {},
upFurniture = {},
upHero = {},
showHero = {8},
cost = {5001,1},
oneDropGroup = {10001,10002,10003,10004,10005,10006},
oneDropWeight = {80,515,1500,6500,415,990},
smallNum = 10,
smallDropGroup = {10001,10002},
smallDropWeight = {80,9920},
probIncrStartNum = 60,
probIncrDropGroup = 10001,
probIncrVal = 1000,
middleNum = 0,
middleDropGroup = {},
middleDropWeight = {},
bigNum = 0,
bigDropGroup = {},
bigDropWeight = {},
firstDropGroup = {10103},
firstDropWeight = {100},
firstDropNum = 50,
gachaMyselfNum = 0,
gachaMyself = {},
firstDrop = 2,
recruitRule = "1、迎新福利：第50次祈灵时，必可获取一位天级门客。\n2、每进行十次祈灵，结果中必包含至少一位门客角色，若在达成十次祈灵前已获得了门客角色，则该进度重新开始计算。",
gachaDesc = "该祈灵为面向新玩家开放的特殊祈灵。",
UPProbability = 5000,
retItemId = {{3,13,20}},
bgPrefab = "shanhetiaotiao",

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
for _, v in pairs(gacha) do
    setmetatable(v, metatable)
end
 
return gacha
