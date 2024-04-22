#pragma once
#include <string.h>
#include <queue>
#include "../../common/Singleton.h"
#include "../../common/net/TcpServer.h"
#include "../../common/net/Data.h"
#include "../../../libs/jemalloc/jemalloc.h"

class MainThread : public Singleton<MainThread>
{
public:
	~MainThread();
	void start(uint16_t port);
	void processClientMessage(Task &t);
	void closeServer();

public:
	bool running_ = true;
	std::atomic<bool> quit_{false};
	TcpServer tcp_;
	std::queue<Task> qt_;
};

#define gMainThread MainThread::instance()