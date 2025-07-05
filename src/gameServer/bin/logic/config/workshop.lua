--keys:id|name|type|nature|workerNumb|furnitureNumb|talentLevelNumb|buff|workshopTalen1|workshopTalen2|need1|workerNumbUp|furnitureNumbUp|talentLevelUp|limitLevel|needCoin|
local workshop={
[1]={id=1,name="揽客",type=1,nature={1,6},workerNumb=1,furnitureNumb=1,talentLevelNumb=0,buff=10000,workshopTalen1=1,workshopTalen2=2,need1={{16,80,1},{16,100,1},{16,120,1},{16,160,1},{16,240,1},{16,330,1},{16,430,1},{16,560,1},{16,700,1},{16,810,1},{16,900,1}},workerNumbUp={2,9,9,9},furnitureNumbUp={2,5},talentLevelUp={{1,1},{2,2},{3,3},{4,4},{5,5},{6,6},{7,7},{8,8},{9,9}},limitLevel=9,needCoin={{1,1000},{1,4000},{1,14600},{1,44000},{1,134000},{1,380000},{1,960000},{1,2000000}},},
[2]={id=2,name="招待",type=1,nature={2,6},workerNumb=1,furnitureNumb=1,talentLevelNumb=0,buff=10000,workshopTalen1=3,workshopTalen2=4,need1={{14,80,1},{14,100,1},{14,120,1},{14,160,1},{14,240,1},{14,330,1},{14,430,1},{14,560,1},{14,700,1},{14,810,1},{14,900,1}},workerNumbUp={2,9,9,9},furnitureNumbUp={2,5},talentLevelUp={{1,1},{2,2},{3,3},{4,4},{5,5},{6,6},{7,7},{8,8},{9,9}},limitLevel=9,needCoin={{1,1000},{1,4000},{1,14600},{1,44000},{1,134000},{1,380000},{1,960000},{1,2000000}},},
[3]={id=3,name="售卖",type=1,nature={3},workerNumb=1,furnitureNumb=1,talentLevelNumb=0,buff=10000,workshopTalen1=5,workshopTalen2=6,need1={{15,80,1},{15,90,1},{15,100,1},{15,110,1},{15,120,1},{15,140,1},{15,160,1},{15,190,1},{15,240,1},{15,290,1},{15,330,1},{15,380,1},{15,430,1},{15,490,1},{15,560,1},{15,620,1},{15,700,1},{15,790,1},{15,810,1},{15,900,1}},workerNumbUp={2,9,9,9},furnitureNumbUp={2,5},talentLevelUp={{1,1},{2,2},{3,3},{4,4},{5,5},{6,6},{7,7},{8,8},{9,9}},limitLevel=9,needCoin={{1,1000},{1,4000},{1,14600},{1,44000},{1,134000},{1,380000},{1,960000},{1,2000000}},},
[4]={id=4,name="武器工坊",type=2,nature={4},workerNumb=1,furnitureNumb=1,talentLevelNumb=0,buff=10000,workshopTalen1=7,workshopTalen2=8,need1={{13,80,1},{13,90,1},{13,100,1},{13,110,1},{13,120,1},{13,140,1},{13,160,1},{13,190,1},{13,240,1},{13,290,1},{13,330,1},{13,380,1},{13,430,1},{13,490,1},{13,560,1},{13,620,1},{13,700,1},{13,790,1},{13,810,1},{13,900,1}},workerNumbUp={2,9,9,9},furnitureNumbUp={2,5},talentLevelUp={{1,1},{2,2},{3,3},{4,4},{5,5},{6,6},{7,7},{8,8},{9,9}},limitLevel=9,needCoin={{1,1250},{1,5000},{1,18250},{1,55000},{1,167500},{1,475000},{1,1200000},{1,2500000}},},
[5]={id=5,name="防具工坊",type=2,nature={5},workerNumb=1,furnitureNumb=1,talentLevelNumb=0,buff=10000,workshopTalen1=9,workshopTalen2=10,need1={{13,80,1},{13,90,1},{13,100,1},{13,110,1},{13,120,1},{13,140,1},{13,160,1},{13,190,1},{13,240,1},{13,290,1},{13,330,1},{13,380,1},{13,430,1},{13,490,1},{13,560,1},{13,620,1},{13,700,1},{13,790,1},{13,810,1},{13,900,1}},workerNumbUp={2,9,9,9},furnitureNumbUp={2,5},talentLevelUp={{1,1},{2,2},{3,3},{4,4},{5,5},{6,6},{7,7},{8,8},{9,9}},limitLevel=9,needCoin={{1,1250},{1,5000},{1,18250},{1,55000},{1,167500},{1,475000},{1,1200000},{1,2500000}},},
[6]={id=6,name="饰品工坊",type=2,nature={2},workerNumb=1,furnitureNumb=1,talentLevelNumb=0,buff=10000,workshopTalen1=11,workshopTalen2=12,need1={{14,80,1},{14,90,1},{14,100,1},{14,110,1},{14,120,1},{14,140,1},{14,160,1},{14,190,1},{14,240,1},{14,290,1},{14,330,1},{14,380,1},{14,430,1},{14,490,1},{14,560,1},{14,620,1},{14,700,1},{14,790,1},{14,810,1},{14,900,1}},workerNumbUp={2,9,9,9},furnitureNumbUp={2,5},talentLevelUp={{1,1},{2,2},{3,3},{4,4},{5,5},{6,6},{7,7},{8,8},{9,9}},limitLevel=9,needCoin={{1,1250},{1,5000},{1,18250},{1,55000},{1,167500},{1,475000},{1,1200000},{1,2500000}},},
[7]={id=7,name="采集",type=3,nature={1},workerNumb=1,furnitureNumb=1,talentLevelNumb=0,buff=10000,workshopTalen1=13,workshopTalen2=14,need1={{16,80,1},{16,90,1},{16,100,1},{16,110,1},{16,120,1},{16,140,1},{16,160,1},{16,190,1},{16,240,1},{16,290,1},{16,330,1},{16,380,1},{16,430,1},{16,490,1},{16,560,1},{16,620,1},{16,700,1},{16,790,1},{16,810,1},{16,900,1}},workerNumbUp={2,9,9,9},furnitureNumbUp={2,5},talentLevelUp={{1,1},{2,2},{3,3},{4,4},{5,5},{6,6},{7,7},{8,8},{9,9}},limitLevel=9,needCoin={{1,1000},{1,4000},{1,14600},{1,44000},{1,134000},{1,380000},{1,960000},{1,2000000}},},
[8]={id=8,name="战斗",type=3,nature={4,5},workerNumb=1,furnitureNumb=2,talentLevelNumb=0,buff=10000,workshopTalen1=0,workshopTalen2=0,need1={{13,80,1},{13,90,1},{13,100,1},{13,110,1},{13,120,1},{13,140,1},{13,160,1},{13,190,1},{13,240,1},{13,290,1},{13,330,1},{13,380,1},{13,430,1},{13,490,1},{13,560,1},{13,620,1},{13,700,1},{13,790,1},{13,810,1},{13,900,1}},workerNumbUp={2,9,9,9},furnitureNumbUp={2,4,6},talentLevelUp={},limitLevel=7,needCoin={{1,1250},{1,5000},{1,18250},{1,55000},{1,167500},{1,475000}},},
[9]={id=9,name="炼丹",type=4,nature={3},workerNumb=1,furnitureNumb=1,talentLevelNumb=0,buff=10000,workshopTalen1=15,workshopTalen2=16,need1={{15,80,1},{15,90,1},{15,100,1},{15,110,1},{15,120,1},{15,140,1},{15,160,1},{15,190,1},{15,240,1},{15,290,1},{15,330,1},{15,380,1},{15,430,1},{15,490,1},{15,560,1},{15,620,1},{15,700,1},{15,790,1},{15,810,1},{15,900,1}},workerNumbUp={2,9,9,9},furnitureNumbUp={2,5},talentLevelUp={{1,1},{2,2},{3,3},{4,4},{5,5},{6,6},{7,7},{8,8},{9,9}},limitLevel=9,needCoin={{1,1000},{1,4000},{1,14600},{1,44000},{1,134000},{1,380000},{1,960000},{1,2000000}},},

}
local empty_table = {}
local default_value = {
    name = "揽客",
type = 1,
nature = {1,6},
workerNumb = 1,
furnitureNumb = 1,
talentLevelNumb = 0,
buff = 10000,
workshopTalen1 = 1,
workshopTalen2 = 2,
need1 = {{16,80,1},{16,100,1},{16,120,1},{16,160,1},{16,240,1},{16,330,1},{16,430,1},{16,560,1},{16,700,1},{16,810,1},{16,900,1}},
workerNumbUp = {2,9,9,9},
furnitureNumbUp = {2,5},
talentLevelUp = {{1,1},{2,2},{3,3},{4,4},{5,5},{6,6},{7,7},{8,8},{9,9}},
limitLevel = 9,
needCoin = {{1,1000},{1,4000},{1,14600},{1,44000},{1,134000},{1,380000},{1,960000},{1,2000000}},

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
for _, v in pairs(workshop) do
    setmetatable(v, metatable)
end
 
return workshop
