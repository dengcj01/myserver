--keys:id|level|taskId|sellTime|loop|priceMagnification|goodwillMagnification|text|
local order_Princess={
[1]={id=1,level=1,taskId=0,sellTime={{180,300},{180,300}},loop=1,priceMagnification=5,goodwillMagnification=10,text="princess_text",},
[3]={id=3,level=2,taskId=0,sellTime={{180,300},{180,300}},loop=1,priceMagnification=5,goodwillMagnification=10,text="princess_text",},
[5]={id=5,level=3,taskId=0,sellTime={{180,300},{180,300}},loop=1,priceMagnification=5,goodwillMagnification=10,text="princess_text",},
[7]={id=7,level=4,taskId=0,sellTime={{180,300},{180,300}},loop=1,priceMagnification=5,goodwillMagnification=10,text="princess_text",},
[9]={id=9,level=5,taskId=0,sellTime={{180,300},{180,300}},loop=1,priceMagnification=5,goodwillMagnification=10,text="princess_text",},
[11]={id=11,level=6,taskId=0,sellTime={{180,300},{180,300}},loop=1,priceMagnification=5,goodwillMagnification=10,text="princess_text",},
[13]={id=13,level=7,taskId=0,sellTime={{180,300},{180,300}},loop=1,priceMagnification=5,goodwillMagnification=10,text="princess_text",},
[15]={id=15,level=8,taskId=0,sellTime={{180,300},{180,300}},loop=1,priceMagnification=5,goodwillMagnification=10,text="princess_text",},
[17]={id=17,level=9,taskId=0,sellTime={{180,300},{180,300}},loop=1,priceMagnification=5,goodwillMagnification=10,text="princess_text",},
[19]={id=19,level=10,taskId=0,sellTime={{180,300},{180,300}},loop=1,priceMagnification=5,goodwillMagnification=10,text="princess_text",},
[21]={id=21,level=11,taskId=0,sellTime={{180,300},{180,300}},loop=1,priceMagnification=5,goodwillMagnification=10,text="princess_text",},

}
local empty_table = {}
local default_value = {
    level = 1,
taskId = 0,
sellTime = {{180,300},{180,300}},
loop = 1,
priceMagnification = 5,
goodwillMagnification = 10,
text = "princess_text",

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
for _, v in pairs(order_Princess) do
    setmetatable(v, metatable)
end
 
return order_Princess
