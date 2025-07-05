--keys:id|hero|weight|furniture|furnitureWeight|
local gachaDropConfig={
[10001]={id=10001,hero={4,5,8,22,27},weight={100,100,100,100,100},furniture={},furnitureWeight={},},
[10002]={id=10002,hero={1,2,3,6,7,9,13,15},weight={100,100,100,100,100,100,100,100},furniture={},furnitureWeight={},},
[10003]={id=10003,hero={},weight={},furniture={130011,130012,130019,130020,130021,140012},furnitureWeight={100,100,100,100,100,100},},
[10004]={id=10004,hero={},weight={},furniture={130007,130009,140010,140011},furnitureWeight={100,100,100,100},},
[10005]={id=10005,hero={},weight={},furniture={210003,210006,210008,210010,210013},furnitureWeight={100,100,100,100,100,100},},
[10006]={id=10006,hero={},weight={},furniture={210000,210002,210007,210009,210011,210012,210025},furnitureWeight={100,100,100,100,100,100,100},},
[10010]={id=10010,hero={4,5,8,10,11,22,23,25,27,33,14},weight={100,100,100,100,100,100,100,100,100,100,100},furniture={},furnitureWeight={},},
[10011]={id=10011,hero={1,2,3,6,7,9,13,15},weight={100,100,100,100,100,100,100,100},furniture={},furnitureWeight={},},
[10012]={id=10012,hero={},weight={},furniture={130011,130012,130019,130020,130021,140012},furnitureWeight={100,100,100,100,100,100},},
[10013]={id=10013,hero={},weight={},furniture={130007,130009,140010,140011},furnitureWeight={100,100,100,100},},
[10014]={id=10014,hero={},weight={},furniture={210003,210006,210008,210010,210013,210015,210018,210019,210020,210022,210023,210024},furnitureWeight={100,100,100,100,100,100,100,100,100,100,100,100},},
[10015]={id=10015,hero={},weight={},furniture={210000,210002,210007,210009,210011,210012,210025},furnitureWeight={100,100,100,100,100,100,100},},
[10020]={id=10020,hero={4,5,10,11,22,23,25,27,30,33,14},weight={100,100,100,100,100,100,100,100,100,100,100},furniture={},furnitureWeight={},},
[10021]={id=10021,hero={1,2,3,6,7,9,13,15},weight={100,100,100,100,100,100,100,100},furniture={},furnitureWeight={},},
[10022]={id=10022,hero={},weight={},furniture={130011,130012,130019,130020,130021,140012},furnitureWeight={100,100,100,100,100,100},},
[10023]={id=10023,hero={},weight={},furniture={130007,130009,140010,140011},furnitureWeight={100,100,100,100},},
[10024]={id=10024,hero={},weight={},furniture={210003,210006,210008,210010,210013,210015,210018,210019,210020,210022,210023,210024},furnitureWeight={100,100,100,100,100,100,100,100,100,100,100,100,100},},
[10025]={id=10025,hero={},weight={},furniture={210000,210002,210007,210009,210011,210012,210025},furnitureWeight={100,100,100,100,100,100,100},},
[10101]={id=10101,hero={4,5,8,10,11,22,23,25,27,33,14},weight={100,100,100,100,100,100,100,100,100,100,100},furniture={},furnitureWeight={},},
[10102]={id=10102,hero={4,5,10,11,22,23,25,27,30,33,14},weight={100,100,100,100,100,100,100,100,100,100,100},furniture={},furnitureWeight={},},
[10103]={id=10103,hero={8},weight={100},furniture={},furnitureWeight={},},
[10104]={id=10104,hero={30},weight={100},furniture={},furnitureWeight={},},
[20001]={id=20001,hero={13,15,25,30,33},weight={1,1,1,1,1},furniture={},furnitureWeight={},},
[20002]={id=20002,hero={25,33},weight={1,1},furniture={},furnitureWeight={},},
[20003]={id=20003,hero={30,33},weight={1,1},furniture={},furnitureWeight={},},

}
local empty_table = {}
local default_value = {
    hero = {4,5,8,22,27},
weight = {100,100,100,100,100},
furniture = {},
furnitureWeight = {},

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
for _, v in pairs(gachaDropConfig) do
    setmetatable(v, metatable)
end
 
return gachaDropConfig
