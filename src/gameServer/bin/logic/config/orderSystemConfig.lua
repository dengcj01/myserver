--keys:lv|conditionLevel|conditionBattleid|conditionEquip|equipDown|downNum|orderAwardtime|refreshTime|speedUptime|speedUpexpend|refreshTimeexPend|totalDifficulty|difficultyRadius|triggerAmend|triggerFrequency|amendNum|orderMax|showReward|
local orderSystemConfig={
[1]={lv=1,conditionLevel=1,conditionBattleid=1010101,conditionEquip=1,equipDown=0,downNum=5,orderAwardtime=1800,refreshTime=15,speedUptime=60,speedUpexpend={3,2,25},refreshTimeexPend={3,2,15},totalDifficulty=8,difficultyRadius={1,2,3},triggerAmend=5,triggerFrequency=3,amendNum=5,orderMax=5,showReward={2,3213,3214,3215,3216,3217,3218,3301,3302,3303,3304,3305,3306,4303,4113,4114,4115,4116,4117,4118,8501,8502,8503,8504,3207,3208,4107,4108,4109,4110,4111,4112,3209,3210,3211,3212,4302,4101,4102,4103,4104,4105,4106,3201,3202,3203,3204,3205,3206,1,4301},},
[2]={lv=2,conditionLevel=10,conditionBattleid=1010101,conditionEquip=2,equipDown=0,downNum=5,orderAwardtime=1800,refreshTime=15,speedUptime=60,speedUpexpend={3,2,25},refreshTimeexPend={3,2,15},totalDifficulty=8,difficultyRadius={1,2,3},triggerAmend=5,triggerFrequency=3,amendNum=5,orderMax=5,showReward={2,3213,3214,3215,3216,3217,3218,3301,3302,3303,3304,3305,3306,4303,4113,4114,4115,4116,4117,4118,8501,8502,8503,8504,3207,3208,4107,4108,4109,4110,4111,4112,3209,3210,3211,3212,4302,4101,4102,4103,4104,4105,4106,3201,3202,3203,3204,3205,3206,1,4301},},
[3]={lv=3,conditionLevel=15,conditionBattleid=1010101,conditionEquip=3,equipDown=0,downNum=5,orderAwardtime=1800,refreshTime=15,speedUptime=60,speedUpexpend={3,2,25},refreshTimeexPend={3,2,15},totalDifficulty=8,difficultyRadius={1,2,3},triggerAmend=5,triggerFrequency=3,amendNum=5,orderMax=5,showReward={2,3213,3214,3215,3216,3217,3218,3301,3302,3303,3304,3305,3306,4303,4113,4114,4115,4116,4117,4118,8501,8502,8503,8504,3207,3208,4107,4108,4109,4110,4111,4112,3209,3210,3211,3212,4302,4101,4102,4103,4104,4105,4106,3201,3202,3203,3204,3205,3206,1,4301},},
[4]={lv=4,conditionLevel=20,conditionBattleid=1010101,conditionEquip=4,equipDown=0,downNum=5,orderAwardtime=1800,refreshTime=15,speedUptime=60,speedUpexpend={3,2,25},refreshTimeexPend={3,2,15},totalDifficulty=8,difficultyRadius={1,2,3},triggerAmend=5,triggerFrequency=3,amendNum=5,orderMax=5,showReward={2,3213,3214,3215,3216,3217,3218,3301,3302,3303,3304,3305,3306,4303,4113,4114,4115,4116,4117,4118,8501,8502,8503,8504,3207,3208,4107,4108,4109,4110,4111,4112,3209,3210,3211,3212,4302,4101,4102,4103,4104,4105,4106,3201,3202,3203,3204,3205,3206,1,4301},},
[5]={lv=5,conditionLevel=25,conditionBattleid=1010101,conditionEquip=5,equipDown=0,downNum=5,orderAwardtime=1800,refreshTime=15,speedUptime=60,speedUpexpend={3,2,25},refreshTimeexPend={3,2,15},totalDifficulty=8,difficultyRadius={1,2,3},triggerAmend=5,triggerFrequency=3,amendNum=5,orderMax=5,showReward={2,3213,3214,3215,3216,3217,3218,3301,3302,3303,3304,3305,3306,4303,4113,4114,4115,4116,4117,4118,8501,8502,8503,8504,3207,3208,4107,4108,4109,4110,4111,4112,3209,3210,3211,3212,4302,4101,4102,4103,4104,4105,4106,3201,3202,3203,3204,3205,3206,1,4301},},
[6]={lv=6,conditionLevel=30,conditionBattleid=1010101,conditionEquip=6,equipDown=2,downNum=5,orderAwardtime=1800,refreshTime=15,speedUptime=60,speedUpexpend={3,2,25},refreshTimeexPend={3,2,15},totalDifficulty=8,difficultyRadius={1,2,3},triggerAmend=5,triggerFrequency=3,amendNum=5,orderMax=5,showReward={2,3213,3214,3215,3216,3217,3218,3301,3302,3303,3304,3305,3306,4303,4113,4114,4115,4116,4117,4118,8501,8502,8503,8504,3207,3208,4107,4108,4109,4110,4111,4112,3209,3210,3211,3212,4302,4101,4102,4103,4104,4105,4106,3201,3202,3203,3204,3205,3206,1,4301},},

}
local empty_table = {}
local default_value = {
    conditionLevel = 1,
conditionBattleid = 1010101,
conditionEquip = 1,
equipDown = 0,
downNum = 5,
orderAwardtime = 1800,
refreshTime = 15,
speedUptime = 60,
speedUpexpend = {3,2,25},
refreshTimeexPend = {3,2,15},
totalDifficulty = 8,
difficultyRadius = {1,2,3},
triggerAmend = 5,
triggerFrequency = 3,
amendNum = 5,
orderMax = 5,
showReward = {2,3213,3214,3215,3216,3217,3218,3301,3302,3303,3304,3305,3306,4303,4113,4114,4115,4116,4117,4118,8501,8502,8503,8504,3207,3208,4107,4108,4109,4110,4111,4112,3209,3210,3211,3212,4302,4101,4102,4103,4104,4105,4106,3201,3202,3203,3204,3205,3206,1,4301},

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
for _, v in pairs(orderSystemConfig) do
    setmetatable(v, metatable)
end
 
return orderSystemConfig
