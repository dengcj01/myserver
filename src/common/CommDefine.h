#pragma once


  // 消息定义
enum ConType
{
	ConType_gate_server     = 1,    // websocket服务器类型
	ConType_log_server      = 2,    // log服务器
	ConType_db_client       = 3,    // tcp db客户端 game->db
	ConType_game_client     = 4,    // tcp 连服客户端 game->主连服
	ConType_log_client      = 5,    // tcp log客户端 game->log
	ConType_master_server   = 6,    // 主连服
	ConType_timer           = 7,    // 定时器消息
	ConType_sql_gm          = 8,    // game进程检查数据库gm指令消息
	ConType_game_server     = 9,    // tcp服务器 特殊的作为game进程服务器类型,有websocket or tcp网关 类型的网关来连接它
	ConType_db_server       = 10,   // db服务器
	ConType_client_gate1    = 11,   // tcp 网关连接游戏服 gate->game
	ConType_client_gate2    = 12,   // tcp 网关连接游戏服 gate->game
	ConType_client_gate3    = 13,   // tcp 网关连接游戏服 gate->game
	ConType_client_gate4    = 14,   // tcp 网关连接游戏服 gate->game
	ConType_center_server   = 15,   // 中心服
	ConType_fight_res       = 16,   // 战斗结果
	ConType_cmd             = 17,   // 命令行消息
	ConType_one_per_time    = 18,   // 每秒消息 -- game进程gm消息和关服消息
	ConType_close           = 19,   // 关服消息
	ConType_gate_tcp_server = 20,   // 网关作为tcp服务器类型 
	ConType_http_gm         = 21,   // 每秒消息 后台发来的消息(一般是主连服处理)
	ConType_http_client     = 22,   // 后台客户端

};



// 服务器关闭客户端原因
#define CoseServer      0  // 服务器关服
#define ExtrusionLine   1  // 挤号
#define BackgroundKick  2  // 后台踢人

// 改名错误原因
#define ChangeNameErrCodeRepeated  2  //名字重复 

  // 需要保持玩家基础数据key定义
enum OfflineDbKeyDef
{
	OfflineDbKeyDefString = 1,   // 字符串
	OfflineDbKeyDefInt    = 2,   // 整数
	offlinedbkeydefint64  = 3,   // 整数64位
	offlinedbkeydeftime   = 4,   // 时间戳
};