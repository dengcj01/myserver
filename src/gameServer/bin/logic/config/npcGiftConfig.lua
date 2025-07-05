--keys:id|guide_note|guide_type|condition|drop|guide_words|role|
local npcGiftConfig={
[1]={id=1,guide_note="xxx送避障香囊图纸",guide_type={0},condition={15},drop={14506},guide_words={"gift_rendong"},role=703,},
[2]={id=2,guide_note="xxx送黄纸律令图纸",guide_type={0},condition={16},drop={14504},guide_words={"guide11"},role=2,},
[3]={id=3,guide_note="xxx送蓝田玉佩图纸",guide_type={0},condition={17},drop={14505},guide_words={"gift_ahula"},role=9,},

}
local empty_table = {}
local default_value = {
    guide_note = "xxx送避障香囊图纸",
guide_type = {0},
condition = {15},
drop = {14506},
guide_words = {"gift_rendong"},
role = 703,

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
for _, v in pairs(npcGiftConfig) do
    setmetatable(v, metatable)
end
 
return npcGiftConfig
