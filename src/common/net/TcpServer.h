

#pragma once

#include <stdint.h>
#include <vector>
#include <thread>
#include <unordered_map>
#include <atomic>

#include "Channel.h"
#include "Data.h"
#include "../Client.h"
//#include "../../../../libs/openssl/ssl.h"

class TcpConnecter;
class EventLoop;


class TcpServer
{
public:
	TcpServer();
	~TcpServer();

public:
	void start(uint16_t port, uint8_t mod=1,bool cmd = false);
	void init(uint16_t port);
	void closeAcceptCb() { acceptCb_ = nullptr; }

	void quitIoLoop();
	void sendMessage2Game(Task& t);
	void sendMessage2DbServer(Task& t);
	void sendMessage2LogServer(Task &t);
	void sendMessage2MasterServer(Task &t);
	bool conExists(uint64_t sessionId);
	uint64_t getSessionId();
	void forceCloseSession(uint64_t sessionId);
	void forceCloseAllSession();
	
private:
	typedef std::function<void()> EventCallBack;
	void initWorkThread(uint8_t mod);
	void setAcceptCb(EventCallBack cb) { acceptCb_ = std::move(cb); }
	void acceptClient();
	void closeClient(uint64_t sessionId);


public:
	uint8_t mod_=1;
	size_t loopIndex_ = 0;
	uint64_t sessionId_ = 2;
	EventLoop* mainEventLoop_;
	Channel* mainChanel_;
	std::thread mainThread_;
	std::thread cmdThread_;
	std::vector<std::thread> threadPool_;
	std::vector<EventLoop*> workLoops_;
	EventCallBack acceptCb_;
	pthread_spinlock_t sp_;

public:
	std::atomic<bool> cmdQuit_{false};
};
