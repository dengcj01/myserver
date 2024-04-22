

#include "MainThread.h"

#include <unordered_map>
#include <pthread.h>

#include "../../common/net/EventLoop.h"
#include "../../common/net/TcpConnecter.h"
#include "../../common/Timer.hpp"
#include "msgHandle/msgHandle.h"
#include "../../../libs/jemalloc/jemalloc.h"
#include "../../common/ParseConfig.hpp"
#include "../../common/CommDefine.h"
extern std::queue<Task> gQueue;
extern std::mutex gMutex;

MainThread::~MainThread()
{
}

void MainThread::start(uint16_t port)
{

	tcp_.start(port, ConType::ConType_log_server);
	logInfo("------------------------------logserver start------------------------------");
	while (running_)
	{

		std::unique_lock<std::mutex> lk(gMutex);
		while (gQueue.empty())
		{
			gCondVar.wait(lk);
		}

		while (!gQueue.empty())
		{
			qt_.push(std::move(gQueue.front()));
			gQueue.pop();
		}

		lk.unlock();

		while (!qt_.empty())
		{

			Task &t = qt_.front();
			processClientMessage(t);

			if (t.data_)
			{
				je_free(t.data_);
			}

			qt_.pop();
		}

		if (quit_.load(std::memory_order_relaxed))
		{
			logQuit("--------------log quit success------------");
			break;
		}
	}
}

void MainThread::processClientMessage(Task &t)
{
	if (t.data_ && t.len_ > 0) 
	{
		uint16_t messageId = 0;
		memcpy(&messageId, t.data_, 2);
		dispatchClientMessage(messageId, t.sessionId_, t.data_ + 2, t.len_ - 2);
	}
}

void MainThread::closeServer()
{
	logInfo("recv game close process message");
	tcp_.quitIoLoop();

	sleep(2);
	quit_.store(true, std::memory_order_relaxed);
	Task t;
	std::unique_lock<std::mutex> lk(gMutex);
	gQueue.emplace(std::move(t));
	gCondVar.notify_one();
}
