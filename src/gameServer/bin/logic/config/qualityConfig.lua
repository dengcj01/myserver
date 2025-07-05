--keys:id|name_langId|attrFactor|priceFactor|expFactor|breakFactor|img|stoneSuccess1|stoneSuccess2|stoneSuccess3|stoneSuccess4|stoneSuccess5|
local qualityConfig={
[1]={id=1,name_langId="qualityConfig_name_1",attrFactor=1,priceFactor=1,expFactor=1,breakFactor=0.01,img="ty_putong_1",stoneSuccess1=1,stoneSuccess2=1,stoneSuccess3=1,stoneSuccess4=1,stoneSuccess5=1,},
[2]={id=2,name_langId="qualityConfig_name_2",attrFactor=1.25,priceFactor=1.25,expFactor=1,breakFactor=0.006,img="ty_xiyou_1",stoneSuccess1=0.3,stoneSuccess2=1,stoneSuccess3=1,stoneSuccess4=1,stoneSuccess5=1,},
[3]={id=3,name_langId="qualityConfig_name_3",attrFactor=1.5,priceFactor=2,expFactor=1,breakFactor=0.004,img="ty_jingpin_1",stoneSuccess1=0.1,stoneSuccess2=0.3,stoneSuccess3=1,stoneSuccess4=1,stoneSuccess5=1,},
[4]={id=4,name_langId="qualityConfig_name_4",attrFactor=1.75,priceFactor=3,expFactor=1,breakFactor=0.002,img="ty_shishi_1",stoneSuccess1=0.03,stoneSuccess2=0.1,stoneSuccess3=0.3,stoneSuccess4=1,stoneSuccess5=1,},
[5]={id=5,name_langId="qualityConfig_name_5",attrFactor=2,priceFactor=5,expFactor=1,breakFactor=0.001,img="ty_chuanshuo_1",stoneSuccess1=0.01,stoneSuccess2=0.03,stoneSuccess3=0.1,stoneSuccess4=0.3,stoneSuccess5=1,},

}

local default_value = {
    name_langId = "qualityConfig_name_1",
attrFactor = 1,
priceFactor = 1,
expFactor = 1,
breakFactor = 0.01,
img = "ty_putong_1",
stoneSuccess1 = 1,
stoneSuccess2 = 1,
stoneSuccess3 = 1,
stoneSuccess4 = 1,
stoneSuccess5 = 1,

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
for _, v in pairs(qualityConfig) do
    setmetatable(v, metatable)
end
 
return qualityConfig
