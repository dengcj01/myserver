#pragma once

#include <stdint.h>
#include <stddef.h>



void reqDbSelectPlayer(uint64_t sessionId, char *data, size_t len);       // 查询玩家
void reqDbCreatePlayer(uint64_t sessionId, char *data, size_t len);       // 创建玩家
void reqDbEnterGame(uint64_t sessionId, char *data, size_t len);          // 进入游戏
void reqDbUpdatePlayerName(uint64_t sessionId, char *data, size_t len);          // 改名


void reqSaveRankData(char *data, size_t len);    // 保存排行榜模块数据
void reqSaveGlobalData(char *data, size_t len);    // 保存全局模块数据
void reqDelRankData(char *data, size_t len);    // 删除排行榜模块数据
void reqUpdatePlayerBaseInfo(char *data, size_t len);    // 更新玩家基础数据

void reqGameQuit(uint64_t sessionId, char *data, size_t len);    // game进程关闭

void dispatchClientMessage(uint16_t messageId, uint64_t sessionId, char *data, size_t len);
