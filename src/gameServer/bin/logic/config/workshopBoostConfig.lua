--keys:id|lvUp|upBonus|name|
local workshopBoostConfig={
[101]={id=101,lvUp={[1]={condition=0,condition1=1,effect={{2001,2},{2002,2},{2003,2},{2004,2}},},[2]={condition=300,condition1=1,effect={{2001,3},{2002,3},{2003,3},{2004,3}},},[3]={condition=500,condition1=1,effect={{2001,20},{2002,20},{2003,20},{2004,20},{2005,10}},},[4]={condition=800,condition1=1,effect={{2001,25},{2002,25},{2003,25},{2004,25},{2005,10},{2006,10}},},},upBonus=0,name="基础生产材料和生成速度[材料id，每分钟采集的数量（需要支持小数点，小数点后面的数转换为概率，每分钟概率可产）]",},
[102]={id=102,lvUp={[1]={condition=0,condition1=1,effect={{3}},},},upBonus=0,name="基础制造队列数量",},
[103]={id=103,lvUp={[1]={condition=0,condition1=2,effect={{2005,2},{2006,3}},},[2]={condition=0,condition1=3,effect={{2005,13},{2006,13}},},},upBonus=0,name="基础生产材料和生成速度[材料id，每分钟采集的数量（需要支持小数点，小数点后面的数转换为概率，每分钟概率可产）]",},

}
local empty_table = {}
local default_value = {
    lvUp={[1]={condition=0,condition1=1,effect={{2001,2},{2002,2},{2003,2},{2004,2}},},[2]={condition=300,condition1=1,effect={{2001,3},{2002,3},{2003,3},{2004,3}},},[3]={condition=500,condition1=1,effect={{2001,20},{2002,20},{2003,20},{2004,20},{2005,10}},},[4]={condition=800,condition1=1,effect={{2001,25},{2002,25},{2003,25},{2004,25},{2005,10},{2006,10}},},},upBonus = 0,
name = "基础生产材料和生成速度[材料id，每分钟采集的数量（需要支持小数点，小数点后面的数转换为概率，每分钟概率可产）]",

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
for _, v in pairs(workshopBoostConfig) do
    setmetatable(v, metatable)
end
 
return workshopBoostConfig
