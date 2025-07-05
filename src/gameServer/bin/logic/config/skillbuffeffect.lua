--keys:effect_id|resource_id|layer_mask|duration|scale|hang_path|
local skillbuffeffect={
[1001]={effect_id=1001,resource_id="buff_fy",layer_mask=11,duration=-1,scale=1,hang_path="head",},
[1002]={effect_id=1002,resource_id="buff_sxjd_1",layer_mask=11,duration=-1,scale=1,hang_path="middle",},
[1003]={effect_id=1003,resource_id="buff_nqts",layer_mask=11,duration=-1,scale=1,hang_path="floor",},
[1004]={effect_id=1004,resource_id="bingdong",layer_mask=2,duration=-1,scale=1,hang_path="floor",},
[1005]={effect_id=1005,resource_id="bingdong_2",layer_mask=11,duration=-1,scale=1,hang_path="floor",},
[1006]={effect_id=1006,resource_id="hudun",layer_mask=2,duration=-1,scale=1,hang_path="middle",},
[1007]={effect_id=1007,resource_id="zhongdu",layer_mask=2,duration=-1,scale=1,hang_path="floor",},
[1008]={effect_id=1008,resource_id="zhuoshao",layer_mask=2,duration=-1,scale=1,hang_path="floor",},
[1009]={effect_id=1009,resource_id="ui_tishi",layer_mask=11,duration=-1,scale=1,hang_path="head",},
[1010]={effect_id=1010,resource_id="jipo",layer_mask=11,duration=1500,scale=1,hang_path="middle",},
[1011]={effect_id=1011,resource_id="liren",layer_mask=11,duration=-1,scale=1,hang_path="head",},
[1012]={effect_id=1012,resource_id="zhongju",layer_mask=11,duration=-1,scale=1,hang_path="head",},
[1013]={effect_id=1013,resource_id="yuanchen",layer_mask=11,duration=-1,scale=1,hang_path="head",},
[1014]={effect_id=1014,resource_id="qibing",layer_mask=11,duration=-1,scale=1,hang_path="head",},
[1015]={effect_id=1015,resource_id="jin",layer_mask=11,duration=-1,scale=1,hang_path="head",},
[1016]={effect_id=1016,resource_id="mu",layer_mask=11,duration=-1,scale=1,hang_path="head",},
[1017]={effect_id=1017,resource_id="shui",layer_mask=11,duration=-1,scale=1,hang_path="head",},
[1018]={effect_id=1018,resource_id="huo",layer_mask=11,duration=-1,scale=1,hang_path="head",},
[1019]={effect_id=1019,resource_id="tu",layer_mask=11,duration=-1,scale=1,hang_path="head",},

}

local default_value = {
    resource_id = "buff_fy",
layer_mask = 11,
duration = -1,
scale = 1,
hang_path = "head",

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
for _, v in pairs(skillbuffeffect) do
    setmetatable(v, metatable)
end
 
return skillbuffeffect
