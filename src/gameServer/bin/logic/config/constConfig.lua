--keys:id|value|
local constConfig={
["deskId"]={id="deskId",value="0",},
["notCarpetId"]={id="notCarpetId",value="0",},
["outDoorAreas"]={id="outDoorAreas",value="0",},
["geneRateTime"]={id="geneRateTime",value="4,6",},
["geneRateTimeLimit"]={id="geneRateTimeLimit",value="3,10",},
["prob"]={id="prob",value="0.02",},
["stayTime"]={id="stayTime",value="3,4",},
["thinkTime"]={id="thinkTime",value="1,2",},
["dialogueTime"]={id="dialogueTime",value="2",},
["lvRange"]={id="lvRange",value="-20,20",},
["customerSpawnCd"]={id="customerSpawnCd",value="3,10",},
["offlineCustomerSpawnCd"]={id="offlineCustomerSpawnCd",value="60",},
["intervalTime"]={id="intervalTime",value="120,180",},
["chatProb"]={id="chatProb",value="0.8,0",},
["equipLevelWeight"]={id="equipLevelWeight",value="0.1,0.1,0.1,0.1,0.1,0.15,0.2,0.15",},
["delegateEquipLevelWeigfht"]={id="delegateEquipLevelWeigfht",value="0.3,0.4,0.3",},
["moveSpeed"]={id="moveSpeed",value="150",},
["obtatinCount"]={id="obtatinCount",value="3",},
["overflowTime"]={id="overflowTime",value="600",},
["furnitureUpgradeHelpCd"]={id="furnitureUpgradeHelpCd",value="1800,5",},
["shopExtendHelpCd"]={id="shopExtendHelpCd",value="1800,5",},
["petMoveSpeed"]={id="petMoveSpeed",value="100",},
["petPlayCd"]={id="petPlayCd",value="30",},
["specialDelegateEnegy"]={id="specialDelegateEnegy",value="0.1",},
["taskSwitch"]={id="taskSwitch",value="3",},
["gachaLimit"]={id="gachaLimit",value="-1",},
["materialEffects"]={id="materialEffects",value="0.3,0.6,1",},
["materialDisplayScale"]={id="materialDisplayScale",value="0.2,0.3,0.6,1",},
["materialFullState"]={id="materialFullState",value="0.3,0.99999,1",},
["questSwith"]={id="questSwith",value="3",},
["taskEquipLevelWeight"]={id="taskEquipLevelWeight",value="4,3,3,1,1",},
["payCoinSwithGem"]={id="payCoinSwithGem",value="1",},
["payCoinSwithGacha"]={id="payCoinSwithGacha",value="255,200",},
["payCoinId"]={id="payCoinId",value="1000",},
["payStore"]={id="payStore",value="104",},
["doublePayNumb"]={id="doublePayNumb",value="2=1000,3=1000,4=1000",},
["discount"]={id="discount",value="0.5",},
["markup"]={id="markup",value="2",},
["gainExp"]={id="gainExp",value="1",},
["buyProb"]={id="buyProb",value="0.05",},
["buyDouble"]={id="buyDouble",value="1000",},
["doubleCusomer"]={id="doubleCusomer",value="1000",},
["workerOut"]={id="workerOut",value="10000",},
["workerEquipQuality"]={id="workerEquipQuality",value="0.59,0.3,0.1,0.01",},
["workerEquipRank"]={id="workerEquipRank",value="3,0",},
["orderPeople"]={id="orderPeople",value="11,22",},
["upgradeChance"]={id="upgradeChance",value="1000,4000,5000",},
["makeNumb"]={id="makeNumb",value="3,5",},
["stoptime"]={id="stoptime",value="0",},

}

local default_value = {
    value = "0",

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
for _, v in pairs(constConfig) do
    setmetatable(v, metatable)
end
 
return constConfig
