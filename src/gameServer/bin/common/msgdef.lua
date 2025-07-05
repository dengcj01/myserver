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
	NotifyServerCloseClient={id=9,lang="cpp",name="NotifyServerCloseClient"}, -- 通知客户端关闭连接
	NotifyPlayerBaseData={id=200,lang="cpp",name="NotifyPlayerBaseData"}, -- 登入下发玩家基础数据
	ReqHeartTick={id=201,lang="cpp",name="ReqHeartTick"}, -- 请求心跳包 // 服务器返回进入游戏后开始发送
	ResHeartTick={id=202,lang="cpp",name="ResHeartTick"}, -- 请求心跳包返回
	ReqServerGm={id=203,lang="lua",name="ReqServerGm"}, -- 执行服务器gm指令
	ReqChangeName={id=204,lang="lua",name="ReqChangeName"}, -- 改名
	ResChangeName={id=205,lang="lua",name="ResChangeName"}, -- 改名返回
	ReqPlayerChangeNameInfo={id=206,lang="lua",name="ReqPlayerChangeNameInfo"}, -- 请求玩家改名数据
	ResPlayerChangeNameInfo={id=207,lang="lua",name="ResPlayerChangeNameInfo"}, -- 请求玩家改名数据返回
	ReqDbSelectPlayer={id=300,lang="lua",name="ReqDbSelectPlayer"}, -- 查询玩家
	ResDbSelectPlayer={id=301,lang="lua",name="ResDbSelectPlayer"}, -- 查询玩家返回
	ReqDbCreatePlayer={id=302,lang="lua",name="ReqDbCreatePlayer"}, -- 创建玩家
	ResDbCreatePlayer={id=303,lang="lua",name="ResDbCreatePlayer"}, -- 创建玩家返回
	ReqDbEnterGame={id=304,lang="lua",name="ReqDbEnterGame"}, -- 请求进入游戏
	ResDbEnterGame={id=305,lang="lua",name="ResDbEnterGame"}, -- 请求进入游戏返回
	ResReturnPlayerBaseData={id=306,lang="lua",name="ResReturnPlayerBaseData"}, -- db返回玩家基础数据
	ResReturnPlayerModuleData={id=307,lang="lua",name="ResReturnPlayerModuleData"}, -- db返回玩家模块数据
	ReqSavePlayerBaseData={id=308,lang="lua",name="ReqSavePlayerBaseData"}, -- db保存玩家基础数据
	ReqSavePlayerModuleData={id=309,lang="lua",name="ReqSavePlayerModuleData"}, -- db保存玩家模块数据
	ReqGameReport={id=310,lang="lua",name="ReqGameReport"}, -- game进程上报自身数据
	ReqGameQuit={id=311,lang="lua",name="ReqGameQuit"}, -- 
	ReqSaveRankData={id=312,lang="lua",name="ReqSaveRankData"}, -- 保存排行榜模块数据
	ReqSaveGlobalData={id=313,lang="lua",name="ReqSaveGlobalData"}, -- 保存全局模块数据
	ReqDelRankData={id=314,lang="lua",name="ReqDelRankData"}, -- 删除排行榜数据
	ReqDelGlobalData={id=315,lang="lua",name="ReqDelGlobalData"}, -- 删除全局数据
	ReqRegPlayerBaseInfo={id=316,lang="cpp",name="ReqRegPlayerBaseInfo"}, -- 玩家登入注册玩家基础数据到跨服/跨服更新到db
	ReqUpdatePlayerBaseInfo={id=317,lang="cpp",name="ReqUpdatePlayerBaseInfo"}, -- 更新玩家基础数据到跨服/跨服更新到db
	ReqDbUpdatePlayerName={id=318,lang="lua",name="ReqDbUpdatePlayerName"}, -- 改名
	ResDbUpdatePlayerName={id=319,lang="lua",name="ResDbUpdatePlayerName"}, -- 改名返回
	ReqCloseDbServer={id=320,lang="lua",name="ReqCloseDbServer"}, -- game发消息关闭db服务器
	ReqAllBagInfo={id=400,lang="lua",name="ReqAllBagInfo"}, -- 请求玩家玩家背包数据
	ResAllBagInfo={id=401,lang="lua",name="ResAllBagInfo"}, -- 请求玩家玩家背包数据返回
	NotifyBagInfoSignUp={id=402,lang="lua",name="NotifyBagInfoSignUp"}, -- 新增道具或者道具信息变化
	NotifyDeleteItem={id=403,lang="lua",name="NotifyDeleteItem"}, -- 删除背包的道具
	ReqCurrencyInfo={id=404,lang="lua",name="ReqCurrencyInfo"}, -- 请求货币数据
	ResCurrencyInfo={id=405,lang="lua",name="ResCurrencyInfo"}, -- 请求货币数据返回
	NotifyCurrencyUpdate={id=406,lang="lua",name="NotifyCurrencyUpdate"}, -- 新增货币或者货币信息变化
	NotifyDeleteCurrency={id=407,lang="lua",name="NotifyDeleteCurrency"}, -- 删除货币
	NotifyClientRewardTips={id=408,lang="lua",name="NotifyClientRewardTips"}, -- 通知客户端获得奖励提示
	ReqBagItemLock={id=409,lang="lua",name="ReqBagItemLock"}, -- 请求装备锁定
	ResBagItemLock={id=410,lang="lua",name="ResBagItemLock"}, -- 请求装备锁定返回
	ReqBagDelItem={id=411,lang="lua",name="ReqBagDelItem"}, -- 请求删除装备
	ReqEquipLevelUp={id=412,lang="lua",name="ReqEquipLevelUp"}, -- 请求装备升级
	ResEquipLevelUp={id=413,lang="lua",name="ResEquipLevelUp"}, -- 请求装备升级返回
	ReqUseItem={id=414,lang="lua",name="ReqUseItem"}, -- 请求使用道具
	ReqMailList={id=500,lang="lua",name="ReqMailList"}, -- 请求邮件列表
	ResMailList={id=501,lang="lua",name="ResMailList"}, -- 请求邮件列表返回
	ReqOptMail={id=502,lang="lua",name="ReqOptMail"}, -- 邮件操作
	ResOptMail={id=503,lang="lua",name="ResOptMail"}, -- 邮件操作返回
	ReqOneKeyOptMail={id=504,lang="lua",name="ReqOneKeyOptMail"}, -- 一键操作邮件
	ResOneKeyOptMail={id=505,lang="lua",name="ResOneKeyOptMail"}, -- 一键操作邮件返回
	NotifyAddNewMail={id=506,lang="lua",name="NotifyAddNewMail"}, -- 服务器推送获得新邮件
	ReqMasterSendMail={id=507,lang="lua",name="ReqMasterSendMail"}, -- 主连服发送邮件
	ReqActiveData={id=600,lang="lua",name="ReqActiveData"}, -- 请求运营活动列表数据
	ResActiveData={id=601,lang="lua",name="ResActiveData"}, -- 请求运营活动列表数据返回
	NotifyOptActive={id=602,lang="lua",name="NotifyOptActive"}, -- 通知客户端开启/闭了活动
	ReqChatInfo={id=700,lang="lua",name="ReqChatInfo"}, -- 请求聊天数据
	ResChatInfo={id=701,lang="lua",name="ResChatInfo"}, -- 请求聊天数据返回
	ReqSendChat={id=702,lang="lua",name="ReqSendChat"}, -- 发送聊天
	NotifyAddNewChat={id=703,lang="lua",name="NotifyAddNewChat"}, -- 推送一条新的聊天数据
	ReqGetCrossChatData={id=704,lang="lua",name="ReqGetCrossChatData"}, -- 连服获取聊天数据
	ResCrossPlayerBaseInfo={id=705,lang="lua",name="ResCrossPlayerBaseInfo"}, -- 主连服返回玩家的基础数据
	ReqCrossSendChat={id=706,lang="lua",name="ReqCrossSendChat"}, -- 客户端发送的聊天消息转给主连服
	ResCrossSendChat={id=707,lang="lua",name="ResCrossSendChat"}, -- 服务器收到主连服的聊天消息
	ReqAddNewChatData={id=708,lang="lua",name="ReqAddNewChatData"}, -- 主连服向其他服发送新增聊天消息(私聊/好友)
	ReqChargeInfo={id=800,lang="lua",name="ReqChargeInfo"}, -- 请求充值数据
	ResChargeInfo={id=801,lang="lua",name="ResChargeInfo"}, -- 请求充值数据返回
	NotifyRetCharge={id=802,lang="lua",name="NotifyRetCharge"}, -- 直充直充返回通知
	ReqStartCharge={id=803,lang="lua",name="ReqStartCharge"}, -- 内网请求充值,发完后,后面的流程是和正式充值是一样的
	ReqFunctionOpenInfo={id=900,lang="lua",name="ReqFunctionOpenInfo"}, -- 请求功能开启信息
	ResFunctionOpenInfo={id=901,lang="lua",name="ResFunctionOpenInfo"}, -- 请求功能开启信息返回
	NotifyFunctionOpenUpdate={id=902,lang="lua",name="NotifyFunctionOpenUpdate"}, -- 通知有新的功能开启
	ReqUseCdkey={id=1000,lang="lua",name="ReqUseCdkey"}, -- 使用兑换码
	ReqSaveNewPeopleGuide={id=1001,lang="lua",name="ReqSaveNewPeopleGuide"}, -- 保存新手引导数据
	ReqGetNewPeopleGuide={id=1002,lang="lua",name="ReqGetNewPeopleGuide"}, -- 请求新手引导数据
	ResGetNewPeopleGuide={id=1003,lang="lua",name="ResGetNewPeopleGuide"}, -- 返回新手引导数据
	ReqSendNewPeopleGuideRd={id=1004,lang="lua",name="ReqSendNewPeopleGuideRd"}, -- 完成指定引导步骤,发奖励
	NotifyAddNewTips={id=1005,lang="lua",name="NotifyAddNewTips"}, -- 服务器通知客户端弹窗
	ReqQuickBuy={id=1006,lang="lua",name="ReqQuickBuy"}, -- 请求快捷购买
	ReqSaveNpcGift={id=1007,lang="lua",name="ReqSaveNpcGift"}, -- 请求保存npc掉落奖励
	ReqNpcGiftData={id=1008,lang="lua",name="ReqNpcGiftData"}, -- 请求未领取npc奖励
	ResNpcGiftData={id=1009,lang="lua",name="ResNpcGiftData"}, -- 未领取npc奖励返回
	ReqNpcGiftRecv={id=1010,lang="lua",name="ReqNpcGiftRecv"}, -- 请求领取npc掉落奖励
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
