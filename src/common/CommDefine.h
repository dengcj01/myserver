#pragma once

#define serversuccess 0			   // 成功
#define servernomath 1			   // 服务器id不匹配
#define serverisonline 2		   // 账号已在线
#define serverpasswderr 3		   // 密码错误
#define serverbanacccount 4		   // 账号已被封禁
#define serverdbautherr 5		   // db登入认证错误
#define serverdbselecterr 6		   // db查询玩家错误
#define serverdbcreateerr 7		   // db创角错误
#define servernoacccount 8		   // 账号不存在
#define serverbanip 9			   // 封ip
#define servernamerepeated 10	   // 名字重复
#define servernameerr 11		   // 名字非法
#define servernoauth 12			   // 未登入验证就查询玩家
#define serverpidrepeated 13	   // 玩家id重复
#define serverplayerisonline 14	   // 玩家已在线
#define serverplayerisnotonline 15 // 玩家不在线
#define serveraccountexists 16	   // db创角已存在该玩家账号,pf,server
#define serveraccountexistsdb 17   // db错误(创角已存在该玩家账号,pf,server)
#define serverdberrbase 18		   // db加载玩家基础数据错误
#define serverdberrbag 19		   // db加载玩家背包数据错误
#define servernofindsession 20	   // 找不到该会话
#define serverreaccountnoplayer 21 // 账号在线但是玩家不在线
#define servernoauthcreate 22	   // 未登入验证就创建玩家
#define servernoauthenter 23	   // 未登入验证就进入游戏
#define serverloadmoduledataerr 24 // db加载玩家模块数据错误
#define serverupdatetimeerr 25	   // db更新玩家登入时间错误

// 消息定义
enum ConType
{
	ConType_gate_server = 1,	// websocket服务器类型
	ConType_log_server = 2,		// log服务器
	ConType_db_client = 3,		// tcp db客户端 game->db
	ConType_game_client = 4,	// tcp 连服客户端 game->主连服
	ConType_log_client = 5,		// tcp log客户端 game->log
	ConType_master_server = 6,	// 主连服
	ConType_timer = 7,			// 定时器消息
	ConType_sql_gm = 8,			// game进程检查数据库gm指令消息
	conType_game_server = 9,	// tcp服务器 特殊的作为game进程服务器类型,有websocket类型的网关来连接它
	ConType_db_server = 10,		// db服务器
	ConType_client_gate1 = 11,	// tcp 网关连接游戏服 gate->game
	ConType_client_gate2 = 12,	// tcp 网关连接游戏服 gate->game
	ConType_client_gate3 = 13,	// tcp 网关连接游戏服 gate->game
	ConType_client_gate4 = 14,	// tcp 网关连接游戏服 gate->game
	ConType_center_server = 15, // 中心服
	ConType_fight_res = 16,		// 战斗结果
	ConType_gamecenter_client = 17, // game进程连接中心服
};

// 服务器强制关闭客户端原因
enum SCCRType
{
	SCCRType_ji_hao = 1, // 强制挤号
};

// 服务器存储过程
#define queryaccount "call queryaccount(?,?,?)"										  // 查询玩家账号数据
#define queryactors "call queryactors(?,?,?)"										  // 查询玩家账号下的玩家id
#define insertactor "call insertactor(?,?,?,?,?,?,?)"								  // 插入玩家基础数据
#define selectlogintime "call selectlogintime(?)"									  // 查询玩家登入时间
#define updatelogintime "call updatelogintime(?,?)"									  // 更新玩家登入时间
#define updateplayerbasedata "call updateplayerbasedata(?,?,?,?,?,?,?,?,?,?,?,?,?,?)" // 更新玩家基础数据
#define queryactor "call queryactor(?)"												  // 查询玩家基础数据
#define queryplayermodule "call queryplayermodule(?,?)"								  // 查询玩家模块数据
#define loadplayerbagdata "call loadplayerbagdata(?)"								  // 加载玩家背包数据

// 游戏服和服务器之间通信协议id定义
enum g2dProtoDefine
{
	g2dReqDbLoginAuth = 1,	  // 查询玩家账号数据
	g2dResDbLoginAuth = 2,	  // 查询玩家账号数据返回
	g2dReqDbSelectPlayer = 3, // 查询玩家
	g2dResDbSelectPlayer = 4, // 查询玩家返回
	g2dReqDbCreatePlayer = 5, // 创建玩家
	g2dResDbCreatePlayer = 6, // 创建玩家返回
	g2dReqDbEnterGame = 7,	  // 请求进入游戏
	g2dResDbEnterGame = 8,	  // 请求进入游戏返回

	g2dResReturnPlayerBaseData = 9,	   // db返回玩家基础数据
	g2dResReturnPlayerBagData = 10,	   // db返回玩家背包数据
	g2dResReturnPlayerModuleData = 11, // db返回玩家模块数据

	g2dReqSavePlayerBaseData = 12,	 // db保存玩家基础数据
	g2dReqSavePlayerBagData = 13,	 // db保存玩家背包数据
	g2dReqSavePlayerModuleData = 14, // db保存玩家模块数据

	g2dReqSendGmToGame = 15, // db发送gm指令到game
	g2mReqGameReport = 16,	 // game进程连接上master后上报自身数据

	g2cReqSelectRepeatedName = 17, // game向center查询玩家名字是否重复
	g2cResSelectRepeatedName = 18, // 向中心服查询名字是否重复返回
	g2cReqReturnNewName = 19,	   // 请求中心服返回一个可用的名字
	g2cResReturnNewName = 20,	   // 请求中心服返回一个可用的名字返回
};

// 物品类型定义
enum ItemTypeDefine
{
	ItemTypeDefine_hero = 1, // 英雄
};



// 属性定义
enum AttrTypeDefine
{
	AttrTypeDefine_hp = 1,		// 生命
	AttrTypeDefine_maxHp = 2,	// 生命上限
	AttrTypeDefine_attack = 3,	// 攻击
	AttrTypeDefine_defense = 4, // 防御
	AttrTypeDefine_speed=5, // 速度

};
