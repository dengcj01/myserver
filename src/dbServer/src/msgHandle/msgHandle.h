#pragma once

#include <stdint.h>
#include <stddef.h>

void reqDbLoginAuth(uint64_t sessionId, char *data, size_t len);          // 登入认证
void reqDbSelectPlayer(uint64_t sessionId, char *data, size_t len);       // 查询玩家
void reqDbCreatePlayer(uint64_t sessionId, char *data, size_t len);       // 创建玩家
void reqDbEnterGame(uint64_t sessionId, char *data, size_t len);          // 进入游戏
void reqSavePlayerBagData(uint64_t sessionId, char *data, size_t len);    // 保存玩家背包数据



void reqGameQuit(uint64_t sessionId, char *data, size_t len);    // game进程关闭

void dispatchClientMessage(uint16_t messageId, uint64_t sessionId, char *data, size_t len);
