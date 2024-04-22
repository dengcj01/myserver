#pragma once

#include <stdint.h>


void dispatchGateClientMessage(uint64_t sessionId, uint16_t messageId, uint64_t csessionId, char *data, size_t len);
void dispatchDbServerMessage(uint8_t messageId, char *data, size_t len);
void reqLoginAuth(uint64_t sessionId, uint64_t csessionId, char *data, size_t len);    // 登入认证
void reqLoginAuthDbReturn(char *data, size_t len);                                     // db登入认证返回
void reqSelectPlayer(uint64_t sessionId, uint64_t csessionId, char *data, size_t len); // 查询玩家角色
void reqSelectPlayerDbReturn(char *data, size_t len);                                  // db查询玩家角色返回
void reqCreatePlayer(uint64_t sessionId, uint64_t csessionId, char *data, size_t len); // 创建玩家
void reqCreatePlayerDbReturn(char *data, size_t len);                                  // db创建玩家返回
void reqEnterGame(uint64_t sessionId, uint64_t csessionId, char *data, size_t len);    // 进入游戏
void resReturnPlayerBagData(char *data, size_t len);                                   // db返回玩家背包数据
void reqEnterGameDbReturn(char *data, size_t len);                                     // db进入游戏返回
void reqBagData(uint64_t sessionId, uint64_t csessionId, char *data, size_t len);      // 请求背包数据
void resReturnPlayerBaseData(char *data, size_t len);                                  // db返回玩家基础数据
void resReturnPlayerModuleData(char *data, size_t len);                                // db返回玩家模块数据
