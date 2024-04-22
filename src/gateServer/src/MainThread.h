#pragma once

#include <thread>
#include <mutex>
#include <unistd.h>
#include <condition_variable>
#include <queue>
#include <string>
#include <unordered_map>
#include "../../common/Singleton.h"
#include "../../../libs/jemalloc/jemalloc.h"
#include "../../common/net/TcpServer.h"
#include "../../common/net/Data.h"


class TcpServer;


class MainThread : public Singleton<MainThread>
{
public:
	~MainThread();
	void start(uint16_t port);
	void closeServer();

private:
	void processClientMessage(Task &t);
	void processGameServerMessage(Task &t);
	void initClient();
	void forward2GameServer(char *data, size_t len, uint64_t sessionId, uint8_t status = 0);

public:
	std::atomic<bool> quit_{false};
	bool isRunning_ = true;
	TcpServer tcp_;
	std::queue<Task> qt_;
	std::atomic<bool> sqlt_{false};
};

#define gMainThread MainThread::instance()