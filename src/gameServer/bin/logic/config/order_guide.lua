--keys:id|target|talkId|itemId|itemCount|npcId|
local order_guide={
[1]={id=1,target=2,talkId="",itemId=1010101,itemCount=1,npcId=0,},
[2]={id=2,target=2,talkId="",itemId=0,itemCount=0,npcId=102,},
[3]={id=3,target=2,talkId="",itemId=0,itemCount=0,npcId=10,},
[4]={id=4,target=3,talkId="",itemId=1110101,itemCount=1,npcId=0,},

}

local default_value = {
    target = 2,
talkId = "",
itemId = 1010101,
itemCount = 1,
npcId = 0,

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
for _, v in pairs(order_guide) do
    setmetatable(v, metatable)
end
 
return order_guide
