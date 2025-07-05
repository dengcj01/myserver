--keys:id|guildPenaltyTime|guildFunctionNum|leaderOfflineTime|guildFoundconsume|guildBanner|guildIcon|guildNameLibrary|guildTextLen|guildNameLen|guildNameNum|guildListCD|guildTextNum|guildLogsNum|guildEffectiveTime|guildApplyCD|guildEffectiveNum|guildNum|guildFunctionEditNum|inheritLeaderMinTime|guildMail1|guildMail2|guildMail3|
local guildBasisConfig={
[0]={id=0,guildPenaltyTime=60,guildFunctionNum={1,3},leaderOfflineTime=600,guildFoundconsume={3,2,100},guildBanner={"biankaung1","tubiao1"},guildIcon={"icon_attribute_fangyu","icon_attribute_baoji","icon_attribute_mingzhong"},guildNameLibrary={"经营广场","文明创建","打开文档"},guildTextLen=180,guildNameLen=12,guildNameNum=2,guildListCD=40,guildTextNum=3,guildLogsNum=30,guildEffectiveTime=120,guildApplyCD=3,guildEffectiveNum=100,guildNum=30,guildFunctionEditNum=10,inheritLeaderMinTime=864000,guildMail1={"退出盟会","已离开%s盟会"},guildMail2={"盟会通知","被踢出%s"},guildMail3={"盟会通知","会长长时间不登录，职位已转让出去给%s"},},

}
local empty_table = {}
local default_value = {
    guildPenaltyTime = 60,
guildFunctionNum = {1,3},
leaderOfflineTime = 600,
guildFoundconsume = {3,2,100},
guildBanner = {"biankaung1","tubiao1"},
guildIcon = {"icon_attribute_fangyu","icon_attribute_baoji","icon_attribute_mingzhong"},
guildNameLibrary = {"经营广场","文明创建","打开文档"},
guildTextLen = 180,
guildNameLen = 12,
guildNameNum = 2,
guildListCD = 40,
guildTextNum = 3,
guildLogsNum = 30,
guildEffectiveTime = 120,
guildApplyCD = 3,
guildEffectiveNum = 100,
guildNum = 30,
guildFunctionEditNum = 10,
inheritLeaderMinTime = 864000,
guildMail1 = {"退出盟会","已离开%s盟会"},
guildMail2 = {"盟会通知","被踢出%s"},
guildMail3 = {"盟会通知","会长长时间不登录，职位已转让出去给%s"},

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
for _, v in pairs(guildBasisConfig) do
    setmetatable(v, metatable)
end
 
return guildBasisConfig
