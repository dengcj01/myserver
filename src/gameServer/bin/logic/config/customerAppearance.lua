--keys:id|part|attachment|pictureName|
local customerAppearance={
[1]={id=1,part=1,attachment="Su_toufa",pictureName="Su_toufa",},
[2]={id=2,part=4,attachment="Su_tou,Su_shenti,Su_youdabi,Su_youdatui,Su_youshou,Su_youxiaotui,Su_zuodabi,Su_zuodatui,Su_zuokua,Su_zuoshou,Su_zuoxiaotui,Su_shadow",pictureName="Su_tou,Su_shenti,Su_youdabi,Su_youdatui,Su_youshou,Su_youxiaotui,Su_zuodabi,Su_zuodatui,Su_zuokua,Su_zuoshou,Su_zuoxiaotui,Su_shadow",},
[3]={id=3,part=3,attachment="Su_youmei,Su_youyan,Su_zui,Su_zuomei,Su_zuoyan",pictureName="youmei_red,youyan_red,zui_red,zuomei_red,zuoyan_red",},
[4]={id=4,part=3,attachment="Su_youmei,Su_youyan,Su_zui,Su_zuomei,Su_zuoyan",pictureName="youmei_red1,youyan_red1,zui_red1,zuomei_red1,zuoyan_red1",},
[5]={id=5,part=3,attachment="Su_youmei,Su_youyan,Su_zui,Su_zuomei,Su_zuoyan",pictureName="youmei_red3,youyan_red3,zui_red3,zuomei_red3,zuoyan_red3",},
[6]={id=6,part=3,attachment="Su_youmei,Su_youyan,Su_zui,Su_zuomei,Su_zuoyan",pictureName="youmei_m,youyan_m,zui_m,zuomei_m,zuoyan_m",},
[17]={id=17,part=3,attachment="Su_youmei,Su_youyan,Su_zui,Su_zuomei,Su_zuoyan",pictureName="Su_youmei,Su_youyan,Su_zui,Su_zuomei,Su_zuoyan",},
[7]={id=7,part=1,attachment="Su_toufa",pictureName="Su_toufa2",},
[8]={id=8,part=1,attachment="Su_toufa",pictureName="Su_toufa3",},
[9]={id=9,part=1,attachment="Su_toufa,Su_toufa4_mao",pictureName="Su_toufa4,Su_toufa4_mao",},
[10]={id=10,part=3,attachment="Su_youmei,Su_youyan,Su_zui,Su_zuomei,Su_zuoyan",pictureName="Su_youmei2,Su_youyan2,Su_zui2,Su_zuomei2,Su_zuoyan2",},
[11]={id=11,part=3,attachment="Su_youmei,Su_youyan,Su_zui,Su_zuomei,Su_zuoyan",pictureName="Su_youmei3,Su_youyan3,Su_zui3,Su_zuomei3,Su_zuoyan3",},
[12]={id=12,part=3,attachment="Su_youmei,Su_youyan,Su_zui,Su_zuomei,Su_zuoyan",pictureName="Su_youmei4,Su_youyan4,Su_zui3,Su_zuomei4,Su_zuoyan4",},

}

local default_value = {
    part = 1,
attachment = "Su_toufa",
pictureName = "Su_toufa",

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
for _, v in pairs(customerAppearance) do
    setmetatable(v, metatable)
end
 
return customerAppearance
