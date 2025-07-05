--keys:id|days|
local mailsConfig={
[1]={id=1,days={[1]={content="号外！号外！官方社群来袭！\n一手游戏消息咨询、专属福利礼包\n交友聊天社群、玩法攻略放送、游戏陪伴答疑！\n\n加入社群，累计16连抽、【天】莫妮莎免费送！更有社群专属京东卡等你来抽！\n\n更多福利欢迎加入\n[url=https://qm.qq.com/q/7ERLfejkaY]官方社群[/url]",name="铸剑阁运营组",title="官方社群奖励",reward={{type=1,id=5001,count=10}},condition=1,time={},duringTime=0,},[2]={content="亲爱的阁主，你有一份问卷请注意查收，您的每一份反馈都是我们前进的动力。\n\n除游戏内必得的奖励外，更有机会赢取百元京东卡！期待与您携手共同见证并助力游戏的成长与蜕变。\n未来，我们将不断优化，只为给您带来更加精彩的游戏体验！\n\n注：请阁主务必填写联系方式，方便我们将奖品发放到你的手中，如有疑问，可加QQ群：561566767\n[url=https://www.wjx.cn/vm/tHpLyPI.aspx#]调查问卷[/url]",name="铸剑阁运营组",title="阁主调查问卷",reward={{type=1,id=5001,count=10}},condition=2,time={2024,11,27},duringTime=0,},[3]={content="各位阁主好，欢迎参加铸剑阁【剑阁重启】删档不付费测试！\n如遇到任何BUG、或对游戏有任何意见和建议，都可以直接填写以下表格\n或直接加入官方社群QQ:561566767，联系群里管理员\n\n可以的话最好可以填写一下信息，程序小哥可以更加准确的定位到问题\n【tap ID】\n【问题描述】\n【截图或视频】（尽量提供，视频可附链接）\n【手机型号】（品牌+机型）\n期待与各位阁主早日相见，重铸剑阁荣光！\n\n[url=https://docs.qq.com/form/page/DQ0R3aG5yRnBXbW5j]BUG&优化反馈表[/url]",name="铸剑阁运营组",title="BUG&优化反馈",reward={{type=1,id=5001,count=10}},condition=2,time={2024,11,27},duringTime=3,},[4]={content="亲爱的阁主大人们：\n\n非常抱歉此次保密测试给大家带来了不好的游戏的体验！苒苒在此非常诚恳且大声的说三遍，抱歉！抱歉！抱歉！\n目前问题已修复，测试的原本意图是想让各位阁主大人体验咱们的新内容，没想到却因为我们的考虑不周，给予阁主大人们糟糕的游戏体验及反馈。\n对于这一严重的失误，我们深知给您带来了极大的不便和困扰，在此向您致以最诚挚的歉意。为了弥补这一损失，我们为您准备了一份特别的补偿方案。您将获得以下补偿内容：\n首日补发60抽，之后每天再各发30抽，稍后会发放额外补偿。\n我们会以此为教训，感谢各位阁主对游戏的支持与理解。",name="铸剑阁运营组",title="致各位阁主们的一封道歉信！",reward={{type=1,id=5001,count=10}},condition=2,time={2024,11,27},duringTime=4,},},},

}
local empty_table = {}
local default_value = {
    days={[1]={content="号外！号外！官方社群来袭！\n一手游戏消息咨询、专属福利礼包\n交友聊天社群、玩法攻略放送、游戏陪伴答疑！\n\n加入社群，累计16连抽、【天】莫妮莎免费送！更有社群专属京东卡等你来抽！\n\n更多福利欢迎加入\n[url=https://qm.qq.com/q/7ERLfejkaY]官方社群[/url]",name="铸剑阁运营组",title="官方社群奖励",reward={{type=1,id=5001,count=10}},condition=1,time={},duringTime=0,},[2]={content="亲爱的阁主，你有一份问卷请注意查收，您的每一份反馈都是我们前进的动力。\n\n除游戏内必得的奖励外，更有机会赢取百元京东卡！期待与您携手共同见证并助力游戏的成长与蜕变。\n未来，我们将不断优化，只为给您带来更加精彩的游戏体验！\n\n注：请阁主务必填写联系方式，方便我们将奖品发放到你的手中，如有疑问，可加QQ群：561566767\n[url=https://www.wjx.cn/vm/tHpLyPI.aspx#]调查问卷[/url]",name="铸剑阁运营组",title="阁主调查问卷",reward={{type=1,id=5001,count=10}},condition=2,time={2024,11,27},duringTime=0,},[3]={content="各位阁主好，欢迎参加铸剑阁【剑阁重启】删档不付费测试！\n如遇到任何BUG、或对游戏有任何意见和建议，都可以直接填写以下表格\n或直接加入官方社群QQ:561566767，联系群里管理员\n\n可以的话最好可以填写一下信息，程序小哥可以更加准确的定位到问题\n【tap ID】\n【问题描述】\n【截图或视频】（尽量提供，视频可附链接）\n【手机型号】（品牌+机型）\n期待与各位阁主早日相见，重铸剑阁荣光！\n\n[url=https://docs.qq.com/form/page/DQ0R3aG5yRnBXbW5j]BUG&优化反馈表[/url]",name="铸剑阁运营组",title="BUG&优化反馈",reward={{type=1,id=5001,count=10}},condition=2,time={2024,11,27},duringTime=3,},[4]={content="亲爱的阁主大人们：\n\n非常抱歉此次保密测试给大家带来了不好的游戏的体验！苒苒在此非常诚恳且大声的说三遍，抱歉！抱歉！抱歉！\n目前问题已修复，测试的原本意图是想让各位阁主大人体验咱们的新内容，没想到却因为我们的考虑不周，给予阁主大人们糟糕的游戏体验及反馈。\n对于这一严重的失误，我们深知给您带来了极大的不便和困扰，在此向您致以最诚挚的歉意。为了弥补这一损失，我们为您准备了一份特别的补偿方案。您将获得以下补偿内容：\n首日补发60抽，之后每天再各发30抽，稍后会发放额外补偿。\n我们会以此为教训，感谢各位阁主对游戏的支持与理解。",name="铸剑阁运营组",title="致各位阁主们的一封道歉信！",reward={{type=1,id=5001,count=10}},condition=2,time={2024,11,27},duringTime=4,},},
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
for _, v in pairs(mailsConfig) do
    setmetatable(v, metatable)
end
 
return mailsConfig
