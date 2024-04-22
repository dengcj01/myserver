
#pragma once

#include <netinet/in.h>
#include <arpa/inet.h>
#include <thread>
#include <string>
#include <unordered_map>
#include <atomic>
#include "net/Data.h"
#include "CommDefine.h"

class EventLoop;
class TcpConnecter;


class Client
{
public:
    Client();
    ~Client();

    static void staticConnectTimer(Args* args);  
    void init(uint8_t mod, uint16_t port, const char* ip="127.0.0.1"); 
    void serverClose(uint64_t sessionId  = 0);
	void sendMessage2Server(Task& t);
    void conncetCallBack();
    void quitClient();
    const char* getName(bool getClientName = false);
    static uint8_t getClientIdx(uint8_t idx);
    static Client* getClient();

public:
    std::atomic<bool> status_{false}; // 真实连接状态
    bool quit_ = false; // 关服的退出标记.服务器服务器退出是不在重复连接server
    uint8_t mod_;
    uint16_t port_;
    int fd_;
    uint64_t sessionId_;
    std::string ip_;
    EventLoop *loop_;
    std::thread ioThread_;
    TcpConnecter *con_;
};
