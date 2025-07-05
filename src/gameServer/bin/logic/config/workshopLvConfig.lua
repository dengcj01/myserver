--keys:id|lvUp|name|nature|natureBoost|workerNumb|buff|limitLevel|workerNumbMax|argument|materitalUnlock|
local workshopLvConfig={
[1]={id=1,lvUp={[1]={needParam=0,needWorker=0,needCoin={0},workshopBoostId={101,103},employment=50,employeeNum=1,},[2]={needParam=100,needWorker=100,needCoin={3,1,1000},workshopBoostId={101,103},employment=100,employeeNum=2,},[3]={needParam=300,needWorker=300,needCoin={3,1,5000},workshopBoostId={101,103},employment=300,employeeNum=3,},[4]={needParam=500,needWorker=500,needCoin={3,1,10000},workshopBoostId={101,103},employment=500,employeeNum=5,},},name="采集工坊",nature={2},natureBoost=5000,workerNumb=1,buff={1,10000},limitLevel=9,workerNumbMax=5,argument=100,materitalUnlock={{2005,11010301,3},{2006,1010303,3}},},
[2]={id=2,lvUp={[1]={needParam=0,needWorker=0,needCoin={0},workshopBoostId={},employment=50,employeeNum=1,},[2]={needParam=100,needWorker=100,needCoin={3,1,1000},workshopBoostId={102},employment=100,employeeNum=2,},[3]={needParam=300,needWorker=300,needCoin={3,1,5000},workshopBoostId={102},employment=300,employeeNum=3,},[4]={needParam=500,needWorker=500,needCoin={3,1,10000},workshopBoostId={102},employment=500,employeeNum=5,},},name="制作工坊",nature={3},natureBoost=5000,workerNumb=1,buff={1,10000},limitLevel=9,workerNumbMax=5,argument=100,materitalUnlock={},},

}
local empty_table = {}
local default_value = {
    lvUp={[1]={needParam=0,needWorker=0,needCoin={0},workshopBoostId={101,103},employment=50,employeeNum=1,},[2]={needParam=100,needWorker=100,needCoin={3,1,1000},workshopBoostId={101,103},employment=100,employeeNum=2,},[3]={needParam=300,needWorker=300,needCoin={3,1,5000},workshopBoostId={101,103},employment=300,employeeNum=3,},[4]={needParam=500,needWorker=500,needCoin={3,1,10000},workshopBoostId={101,103},employment=500,employeeNum=5,},},name = "采集工坊",
nature = {2},
natureBoost = 5000,
workerNumb = 1,
buff = {1,10000},
limitLevel = 9,
workerNumbMax = 5,
argument = 100,
materitalUnlock = {{2005,11010301,3},{2006,1010303,3}},

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
for _, v in pairs(workshopLvConfig) do
    setmetatable(v, metatable)
end
 
return workshopLvConfig
