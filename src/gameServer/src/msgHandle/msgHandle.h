#pragma once

#include <stdint.h>
#include <stddef.h>



void dispatchGateClientMessage(uint64_t sessionId, uint16_t messageId, uint64_t csessionId, char *data, size_t len);
void dispatchDbServerMessage(uint16_t messageId, char *data, size_t len);
void dispatchGameClientMessage(uint16_t messageId, uint64_t sessionId, char *data, size_t len);


void reqLoginAuth(uint64_t sessionId, uint64_t csessionId, char *data, size_t len);    // 登入认证
//void reqLoginAuthDbReturn(char *data, size_t len);                                     // db登入认证返回
void reqSelectPlayer(uint64_t sessionId, uint64_t csessionId, char *data, size_t len); // 查询玩家角色
void reqSelectPlayerDbReturn(char *data, size_t len);                                  // db查询玩家角色返回
void reqCreatePlayer(uint64_t sessionId, uint64_t csessionId, char *data, size_t len); // 创建玩家
void reqCreatePlayerDbReturn(char *data, size_t len);                                  // db创建玩家返回
void reqEnterGame(uint64_t sessionId, uint64_t csessionId, char *data, size_t len);    // 进入游戏
void reqEnterGameDbReturn(char *data, size_t len);                                     // db进入游戏返回

void resReturnPlayerBaseData(char *data, size_t len);                                  // db返回玩家基础数据
void resReturnPlayerModuleData(char *data, size_t len);                                // db返回玩家模块数据
void resDbUpdatePlayerName(char *data, size_t len);    // 修改玩家名字返回





void reqRegPlayerBaseInfo(uint64_t sessionId, char *data, size_t len);// 向跨服注册玩家基础数据
void reqUpdatePlayerBaseInfo(uint64_t sessionId, char *data, size_t len);// 更新玩家基础数据到跨服
void notifyCloseGame(uint64_t sessionId, char *data, size_t len);
