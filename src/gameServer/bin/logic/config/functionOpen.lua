--keys:id|name|open_condition|parameter|toLayer|tabIndex|group|not_open_tips|show_style|new_panel_show|icon|icon2|desc|costGold|costGem|
local functionOpen={
[1001]={id=1001,name="冒险（天下）（",open_condition={0},parameter={},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=0,new_panel_show=0,icon="",icon2="",desc="天下",costGold=0,costGem=0,},
[1002]={id=1002,name="有无商行",open_condition={1},parameter={10},toLayer="BulkDealLayer",tabIndex={},group={},not_open_tips="未开启提示",show_style=2,new_panel_show=1,icon="",icon2="icon_yunxiangyi",desc="有无商行",costGold=5000,costGem=0,},
[1004]={id=1004,name="邮件",open_condition={0},parameter={},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=3,new_panel_show=1,icon="",icon2="",desc="邮件",costGold=0,costGem=0,},
[1005]={id=1005,name="铸造",open_condition={0},parameter={},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=0,new_panel_show=0,icon="",icon2="",desc="铸造",costGold=0,costGem=0,},
[1008]={id=1008,name="涨价降价",open_condition={0},parameter={},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=0,new_panel_show=0,icon="",icon2="",desc="涨价降价",costGold=0,costGem=0,},
[1009]={id=1009,name="前尘回梦",open_condition={0},parameter={},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=1,new_panel_show=0,icon="",icon2="",desc="前尘回梦",costGold=0,costGem=0,},
[1010]={id=1010,name="日常任务与新手任务",open_condition={1},parameter={1},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=1,new_panel_show=1,icon="",icon2="",desc="任务",costGold=0,costGem=0,},
[1011]={id=1011,name="签到",open_condition={1},parameter={999},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=1,new_panel_show=1,icon="",icon2="",desc="签到",costGold=2000,costGem=0,},
[1012]={id=1012,name="角色",open_condition={0},parameter={},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=1,new_panel_show=1,icon="",icon2="",desc="角色",costGold=0,costGem=0,},
[1013]={id=1013,name="工坊",open_condition={0},parameter={},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=0,new_panel_show=0,icon="",icon2="icon_yaoshengu",desc="工坊",costGold=0,costGem=0,},
[1014]={id=1014,name="招募",open_condition={1},parameter={1},toLayer="GachaLayer",tabIndex={},group={},not_open_tips="未开启提示",show_style=1,new_panel_show=1,icon="",icon2="",desc="招募",costGold=0,costGem=0,},
[1015]={id=1015,name="商城",open_condition={0},parameter={},toLayer="StoreLayer",tabIndex={},group={},not_open_tips="未开启提示",show_style=2,new_panel_show=0,icon="",icon2="icon_meirenbufang",desc="商城",costGold=0,costGem=0,},
[1016]={id=1016,name="副本",open_condition={2},parameter={1010213},toLayer="InstanceLayer",tabIndex={},group={1017,1032,0,0},not_open_tips="未开启提示",show_style=2,new_panel_show=1,icon="",icon2="",desc="副本",costGold=0,costGem=0,},
[1017]={id=1017,name="秘境",open_condition={2},parameter={1010213},toLayer="ChallengeLayer",tabIndex={},group={},not_open_tips="未开启提示",show_style=1,new_panel_show=1,icon="fb_fubenmijing",icon2="",desc="百川千峦，虽逢险境，亦生珍奇。",costGold=0,costGem=0,},
[1018]={id=1018,name="后山",open_condition={0},parameter={},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=1,new_panel_show=1,icon="",icon2="",desc="后山",costGold=0,costGem=0,},
[1019]={id=1019,name="设计",open_condition={0},parameter={},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=1,new_panel_show=1,icon="",icon2="",desc="设计",costGold=0,costGem=0,},
[1020]={id=1020,name="章节任务",open_condition={1},parameter={8},toLayer="ChapterTaskLayer",tabIndex={},group={},not_open_tips="未开启提示",show_style=1,new_panel_show=1,icon="",icon2="icon_junjichu",desc="任务",costGold=0,costGem=0,},
[1021]={id=1021,name="新手任务",open_condition={1},parameter={1},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=1,new_panel_show=1,icon="",icon2="",desc="任务",costGold=0,costGem=0,},
[1022]={id=1022,name="日常任务",open_condition={1},parameter={1},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=1,new_panel_show=1,icon="",icon2="icon_junjichu",desc="任务",costGold=0,costGem=0,},
[1023]={id=1023,name="玩家信息",open_condition={0},parameter={},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=0,new_panel_show=0,icon="",icon2="",desc="玩家信息",costGold=0,costGem=0,},
[1024]={id=1024,name="顾客",open_condition={0},parameter={},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=0,new_panel_show=0,icon="",icon2="",desc="顾客",costGold=0,costGem=0,},
[1025]={id=1025,name="组队",open_condition={0},parameter={},toLayer="FormationLayer",tabIndex={},group={},not_open_tips="未开启提示",show_style=0,new_panel_show=0,icon="",icon2="",desc="组队",costGold=0,costGem=0,},
[1026]={id=1026,name="扩展铸造",open_condition={0},parameter={},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=0,new_panel_show=0,icon="",icon2="",desc="扩展铸造",costGold=0,costGem=0,},
[1027]={id=1027,name="一键采集",open_condition={0},parameter={},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=0,new_panel_show=0,icon="",icon2="",desc="扩展铸造",costGold=0,costGem=0,},
[1028]={id=1028,name="解锁建筑",open_condition={0},parameter={},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=0,new_panel_show=0,icon="",icon2="",desc="扩展铸造",costGold=0,costGem=0,},
[1029]={id=1029,name="天工谱",open_condition={1},parameter={5},toLayer="EquipTaskLayer",tabIndex={},group={},not_open_tips="未开启提示",show_style=2,new_panel_show=1,icon="",icon2="icon_zhujiange",desc="天工谱",costGold=0,costGem=0,},
[1030]={id=1030,name="招募",open_condition={1},parameter={2},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=0,new_panel_show=0,icon="",icon2="",desc="招募",costGold=0,costGem=0,},
[1031]={id=1031,name="蜃楼",open_condition={1},parameter={999},toLayer="TowerLayer",tabIndex={},group={},not_open_tips="未开启提示",show_style=0,new_panel_show=0,icon="sl_shenlou",icon2="",desc="充满各种未知的楼宇",costGold=0,costGem=0,},
[1032]={id=1032,name="琳琅市集",open_condition={1},parameter={13},toLayer="OperateVerifyLayer",tabIndex={},group={},not_open_tips="未开启提示",show_style=0,new_panel_show=0,icon="fb_tunshitiandi",icon2="icon_yunxiangyi",desc="云麓之上，各处市集琳琅熙攘，其中似乎蕴藏着新的商机……",costGold=0,costGem=0,},
[1033]={id=1033,name="成就",open_condition={1},parameter={6},toLayer="AchieveLayer",tabIndex={},group={},not_open_tips="未开启提示",show_style=2,new_panel_show=1,icon="",icon2="",desc="成就",costGold=0,costGem=0,},
[1034]={id=1034,name="书案",open_condition={1},parameter={11},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=0,new_panel_show=0,icon="",icon2="",desc="书案",costGold=0,costGem=0,},
[1035]={id=1035,name="盟会",open_condition={1},parameter={5},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=0,new_panel_show=0,icon="",icon2="",desc="书案",costGold=0,costGem=0,},
[2000]={id=2000,name="八日嘉年华",open_condition={1,3},parameter={2,21},toLayer="",tabIndex={},group={},not_open_tips="未开启提示",show_style=0,new_panel_show=0,icon="",icon2="",desc="八日签到",costGold=0,costGem=0,},

}
local empty_table = {}
local default_value = {
    name = "冒险（天下）（",
open_condition = {0},
parameter = {},
toLayer = "",
tabIndex = {},
group = {},
not_open_tips = "未开启提示",
show_style = 0,
new_panel_show = 0,
icon = "",
icon2 = "",
desc = "天下",
costGold = 0,
costGem = 0,

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
for _, v in pairs(functionOpen) do
    setmetatable(v, metatable)
end
 
return functionOpen
