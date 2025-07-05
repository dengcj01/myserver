--keys:id|name|makeProp|useProp|workerNumb|needLevel|
local alchemy={
[1]={id=1,name="游灵丹",makeProp={5101,10},useProp={{2004,50}},workerNumb=480,needLevel=0,},
[2]={id=2,name="聚灵丹",makeProp={5102,9},useProp={{2004,100}},workerNumb=480,needLevel=4,},
[3]={id=3,name="涌灵丹",makeProp={5103,8},useProp={{2004,150}},workerNumb=480,needLevel=7,},
[4]={id=4,name="染驳晶",makeProp={5104,4},useProp={{2001,50}},workerNumb=480,needLevel=0,},
[5]={id=5,name="降尘晶",makeProp={5105,3},useProp={{2001,100}},workerNumb=480,needLevel=4,},
[6]={id=6,name="扶光晶",makeProp={5106,2},useProp={{2001,150}},workerNumb=480,needLevel=7,},

}
local empty_table = {}
local default_value = {
    name = "游灵丹",
makeProp = {5101,10},
useProp = {{2004,50}},
workerNumb = 480,
needLevel = 0,

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
for _, v in pairs(alchemy) do
    setmetatable(v, metatable)
end
 
return alchemy
