--keys:id|name|workerNumbUp|furnitureNumbUp|levelUp|
local workshopUpgrade={
[1]={id=1,name="武器房间升级",workerNumbUp={},furnitureNumbUp={},levelUp={},},

}
local empty_table = {}
local default_value = {
    name = "武器房间升级",
workerNumbUp = {},
furnitureNumbUp = {},
levelUp = {},

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
for _, v in pairs(workshopUpgrade) do
    setmetatable(v, metatable)
end
 
return workshopUpgrade
