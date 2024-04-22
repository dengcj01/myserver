local cacheMsg = {}

local function regMsg(msgId, msgName, lang)
	local name = cacheMsg[msgId]
	if name and name == msgName then
		print("msgName repeated", msgId, msgName)
		return
	end

	cacheMsg[msgId] = msgName
	gMainThread:cacheMessage(msgId, lang, msgName, "")
end

ProtoDef=
{
	ReqLoginAuth={id=1,lang="cpp",name="ReqLoginAuth"}, -- 请求登入认证
	ResLoginAuth={id=2,lang="cpp",name="ResLoginAuth"}, -- 登入认证返回
	ReqSelectPlayer={id=3,lang="cpp",name="ReqSelectPlayer"}, -- 查询玩家
	ResSelectPlayer={id=4,lang="cpp",name="ResSelectPlayer"}, -- 查询玩家返回
	ReqCreatePlayer={id=5,lang="cpp",name="ReqCreatePlayer"}, -- 请求创建玩家
	ResCreatePlayer={id=6,lang="cpp",name="ResCreatePlayer"}, -- 创建玩家返回
	ReqEnterGame={id=7,lang="cpp",name="ReqEnterGame"}, -- 请求进入游戏
	ResEnterGame={id=8,lang="cpp",name="ResEnterGame"}, -- 请求进入游戏返回
	ResServerCloseClient={id=9,lang="cpp",name="ResServerCloseClient"}, -- 服务器强制关闭客户端
	ReqBagData={id=10,lang="cpp",name="ReqBagData"}, -- 请求背包数据
	ResBagData={id=11,lang="cpp",name="ResBagData"}, -- 请求背包数据返回
	ResServerOptItem={id=12,lang="cpp",name="ResServerOptItem"}, -- 服务器操作背包
	ResBagItemCntUpdate={id=13,lang="cpp",name="ResBagItemCntUpdate"}, -- 道具数量变化
	ResNoticeItemReward={id=14,lang="lua",name="ResNoticeItemReward"}, -- 推送获得奖励提示
	ReqActiveData={id=15,lang="lua",name="ReqActiveData"}, -- 请求运营活动列表数据
	ResActiveData={id=16,lang="lua",name="ResActiveData"}, -- 请求运营活动列表数据返回
	ResNoticeOptActive={id=17,lang="lua",name="ResNoticeOptActive"}, -- 通知客户端开启/闭了活动
	ReqActiveConf={id=18,lang="lua",name="ReqActiveConf"}, -- 请求活动配置
	ResActiveConf={id=19,lang="lua",name="ResActiveConf"}, -- 请求活动配置返回
	ReqMailList={id=20,lang="lua",name="ReqMailList"}, -- 请求邮件列表
	ResMailList={id=21,lang="lua",name="ResMailList"}, -- 请求邮件列表返回
	ReqOptMail={id=22,lang="lua",name="ReqOptMail"}, -- 邮件操作
	ResOptMail={id=23,lang="lua",name="ResOptMail"}, -- 邮件操作返回
	ReqOneKeyOptMail={id=24,lang="lua",name="ReqOneKeyOptMail"}, -- 一键操作邮件
	ResOneKeyOptMail={id=25,lang="lua",name="ResOneKeyOptMail"}, -- 一键操作邮件返回
	ResSendMail={id=26,lang="lua",name="ResSendMail"}, -- 发送跨服邮件
	ReqFight={id=27,lang="lua",name="ReqFight"}, -- 请求战斗
	ResFight={id=28,lang="lua",name="ResFight"}, -- 请求战斗返回
	ReqHeroList={id=29,lang="lua",name="ReqHeroList"}, -- 请求英雄列表
	ResHeroList={id=30,lang="lua",name="ResHeroList"}, -- 请求英雄列表返回
	ResNewHeroList={id=31,lang="lua",name="ResNewHeroList"}, -- 获得新英雄
}

for k, v in pairs(ProtoDef) do
	regMsg(v.id, k, v.lang)
end

function gGetCppProto()
	local tab = {}
	for k, v in pairs(ProtoDef) do
		if v.lang == 'cpp' then tab[v.id]=k end
	end
	return tab
end

cacheMsg = nil
