--keys:id|level|icon|exp|tileDescription|unlockContent|reward|
local ratingLevel={
[1]={id=1,level=1,icon="level1",exp=60,tileDescription="僻静陋室-1",unlockContent={},reward={12001},},
[2]={id=2,level=2,icon="level1",exp=180,tileDescription="僻静陋室-2",unlockContent={1,2},reward={12002},},
[3]={id=3,level=3,icon="level1",exp=300,tileDescription="僻静陋室-3",unlockContent={},reward={12003,12000},},
[4]={id=4,level=4,icon="level1",exp=420,tileDescription="僻静陋室-4",unlockContent={},reward={12004},},
[5]={id=5,level=5,icon="level1",exp=540,tileDescription="僻静陋室-5",unlockContent={10},reward={12005},},
[6]={id=6,level=6,icon="level1",exp=660,tileDescription="僻静陋室-6",unlockContent={9},reward={12006},},
[7]={id=7,level=7,icon="level1",exp=780,tileDescription="僻静陋室-7",unlockContent={},reward={12007},},
[8]={id=8,level=8,icon="level1",exp=900,tileDescription="僻静陋室-8",unlockContent={11},reward={12008},},
[9]={id=9,level=9,icon="level1",exp=1020,tileDescription="僻静陋室-9",unlockContent={20},reward={12009},},
[10]={id=10,level=10,icon="level1",exp=1140,tileDescription="僻静陋室-10",unlockContent={6,26,18},reward={12010,12000},},
[11]={id=11,level=11,icon="level2",exp=1400,tileDescription="片瓦单屋-1",unlockContent={17,21},reward={12011},},
[12]={id=12,level=12,icon="level2",exp=5200,tileDescription="片瓦单屋-2",unlockContent={8},reward={12012},},
[13]={id=13,level=13,icon="level2",exp=9000,tileDescription="片瓦单屋-3",unlockContent={12},reward={12013},},
[14]={id=14,level=14,icon="level2",exp=12800,tileDescription="片瓦单屋-4",unlockContent={3,38,36},reward={12014},},
[15]={id=15,level=15,icon="level2",exp=16600,tileDescription="片瓦单屋-5",unlockContent={35,13,14,15},reward={12015,12000},},
[16]={id=16,level=16,icon="level2",exp=20400,tileDescription="片瓦单屋-6",unlockContent={27,39},reward={12016},},
[17]={id=17,level=17,icon="level2",exp=34200,tileDescription="片瓦单屋-7",unlockContent={7,16,30},reward={12017},},
[18]={id=18,level=18,icon="level2",exp=48000,tileDescription="片瓦单屋-8",unlockContent={4,29},reward={12018},},
[19]={id=19,level=19,icon="level2",exp=61800,tileDescription="片瓦单屋-9",unlockContent={54,51},reward={12019},},
[20]={id=20,level=20,icon="level2",exp=75600,tileDescription="片瓦单屋-10",unlockContent={19,22,23,24},reward={12020,12000},},
[21]={id=21,level=21,icon="level3",exp=89600,tileDescription="无名小筑-1",unlockContent={34,55},reward={12021},},
[22]={id=22,level=22,icon="level3",exp=140800,tileDescription="无名小筑-2",unlockContent={25},reward={12022},},
[23]={id=23,level=23,icon="level3",exp=192000,tileDescription="无名小筑-3",unlockContent={},reward={12023},},
[24]={id=24,level=24,icon="level3",exp=243200,tileDescription="无名小筑-4",unlockContent={68},reward={12024},},
[25]={id=25,level=25,icon="level3",exp=294400,tileDescription="无名小筑-5",unlockContent={28,31,32,33},reward={12025},},
[26]={id=26,level=26,icon="level3",exp=345600,tileDescription="无名小筑-6",unlockContent={44,69,81},reward={12026,12000},},
[27]={id=27,level=27,icon="level3",exp=460800,tileDescription="无名小筑-7",unlockContent={43},reward={12027},},
[28]={id=28,level=28,icon="level3",exp=576000,tileDescription="无名小筑-8",unlockContent={37,72},reward={12028},},
[29]={id=29,level=29,icon="level3",exp=691200,tileDescription="无名小筑-9",unlockContent={82},reward={12029},},
[30]={id=30,level=30,icon="level3",exp=806400,tileDescription="无名小筑-10",unlockContent={52,40,41,42},reward={12030},},
[31]={id=31,level=31,icon="level4",exp=921600,tileDescription="冶金小榭-1",unlockContent={50,73,83,46},reward={12031},},
[32]={id=32,level=32,icon="level4",exp=1324800,tileDescription="冶金小榭-2",unlockContent={60,53,45},reward={12032,12000},},
[33]={id=33,level=33,icon="level4",exp=1728000,tileDescription="冶金小榭-3",unlockContent={74},reward={12033},},
[34]={id=34,level=34,icon="level4",exp=2131200,tileDescription="冶金小榭-4",unlockContent={84,67},reward={12034},},
[35]={id=35,level=35,icon="level4",exp=2534400,tileDescription="冶金小榭-5",unlockContent={65,47,48,49},reward={12035},},
[36]={id=36,level=36,icon="level4",exp=2937600,tileDescription="冶金小榭-6",unlockContent={59,75,85},reward={12036},},
[37]={id=37,level=37,icon="level4",exp=3916800,tileDescription="冶金小榭-7",unlockContent={61},reward={12037,12000},},
[38]={id=38,level=38,icon="level4",exp=4896000,tileDescription="冶金小榭-8",unlockContent={76},reward={12038},},
[39]={id=39,level=39,icon="level4",exp=5875200,tileDescription="冶金小榭-9",unlockContent={86},reward={12039},},
[40]={id=40,level=40,icon="level4",exp=6854400,tileDescription="冶金小榭-10",unlockContent={56,57,58},reward={12040},},
[41]={id=41,level=41,icon="level5",exp=7833600,tileDescription="筑土坚台-1",unlockContent={64,77,87},reward={12041},},
[42]={id=42,level=42,icon="level5",exp=9976800,tileDescription="筑土坚台-2",unlockContent={66},reward={12042},},
[43]={id=43,level=43,icon="level5",exp=12120000,tileDescription="筑土坚台-3",unlockContent={78},reward={12043,12000},},
[44]={id=44,level=44,icon="level5",exp=14263200,tileDescription="筑土坚台-4",unlockContent={88,63},reward={12044},},
[45]={id=45,level=45,icon="level5",exp=16406400,tileDescription="筑土坚台-5",unlockContent={62},reward={12045},},
[46]={id=46,level=46,icon="level5",exp=18549600,tileDescription="筑土坚台-6",unlockContent={70,79,89},reward={12046},},
[47]={id=47,level=47,icon="level5",exp=22072800,tileDescription="筑土坚台-7",unlockContent={71},reward={12047,12000},},
[48]={id=48,level=48,icon="level5",exp=25596000,tileDescription="筑土坚台-8",unlockContent={80},reward={12048},},
[49]={id=49,level=49,icon="level5",exp=29119200,tileDescription="筑土坚台-9",unlockContent={},reward={12049},},
[50]={id=50,level=50,icon="level5",exp=32642400,tileDescription="筑土坚台-10",unlockContent={},reward={12050,12000},},
[51]={id=51,level=51,icon="level6",exp=630851000,tileDescription="重堂高阁-1",unlockContent={},reward={12050},},
[52]={id=52,level=52,icon="level6",exp=630851000,tileDescription="重堂高阁-2",unlockContent={},reward={12050},},
[53]={id=53,level=53,icon="level6",exp=630851000,tileDescription="重堂高阁-3",unlockContent={},reward={12050},},
[54]={id=54,level=54,icon="level6",exp=630851000,tileDescription="重堂高阁-4",unlockContent={},reward={12050},},
[55]={id=55,level=55,icon="level6",exp=630851000,tileDescription="重堂高阁-5",unlockContent={},reward={12050},},
[56]={id=56,level=56,icon="level6",exp=630851000,tileDescription="重堂高阁-6",unlockContent={},reward={12050},},
[57]={id=57,level=57,icon="level6",exp=630851000,tileDescription="重堂高阁-7",unlockContent={},reward={12050},},
[58]={id=58,level=58,icon="level6",exp=630851000,tileDescription="重堂高阁-8",unlockContent={},reward={12050},},
[59]={id=59,level=59,icon="level6",exp=630851000,tileDescription="重堂高阁-9",unlockContent={},reward={12050},},
[60]={id=60,level=60,icon="level6",exp=630851000,tileDescription="重堂高阁-10",unlockContent={},reward={12050},},
[61]={id=61,level=61,icon="level7",exp=630851000,tileDescription="雕栏玉苑-1",unlockContent={},reward={12050},},
[62]={id=62,level=62,icon="level7",exp=630851000,tileDescription="雕栏玉苑-2",unlockContent={},reward={12050},},
[63]={id=63,level=63,icon="level7",exp=630851000,tileDescription="雕栏玉苑-3",unlockContent={},reward={12050},},
[64]={id=64,level=64,icon="level7",exp=630851000,tileDescription="雕栏玉苑-4",unlockContent={},reward={12050},},
[65]={id=65,level=65,icon="level7",exp=630851000,tileDescription="雕栏玉苑-5",unlockContent={},reward={12050},},
[66]={id=66,level=66,icon="level7",exp=630851000,tileDescription="雕栏玉苑-6",unlockContent={},reward={12050},},
[67]={id=67,level=67,icon="level7",exp=630851000,tileDescription="雕栏玉苑-7",unlockContent={},reward={12050},},
[68]={id=68,level=68,icon="level7",exp=630851000,tileDescription="雕栏玉苑-8",unlockContent={},reward={12050},},
[69]={id=69,level=69,icon="level7",exp=630851000,tileDescription="雕栏玉苑-9",unlockContent={},reward={12050},},
[70]={id=70,level=70,icon="level7",exp=630851000,tileDescription="雕栏玉苑-10",unlockContent={},reward={12050},},

}
local empty_table = {}
local default_value = {
    level = 1,
icon = "level1",
exp = 60,
tileDescription = "僻静陋室-1",
unlockContent = {},
reward = {12001},

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
for _, v in pairs(ratingLevel) do
    setmetatable(v, metatable)
end
 
return ratingLevel
