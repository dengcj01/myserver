

#include "MainThread.h"

#include <unordered_map>
#include <pthread.h>
#include <unistd.h>
#include <regex>
#include "../../common/net/EventLoop.h"
#include "../../common/net/TcpConnecter.h"
#include "../../common/Timer.hpp"
#include "msgHandle/msgHandle.h"
#include "../../common/MysqlClient.h"
#include "../../../libs/mysql/mysql_connection.h"
#include "../../../libs/mysql/mysql_error.h"
#include "../../../libs/mysql/cppconn/resultset.h"
#include "../../../libs/mysql/cppconn/statement.h"
#include "../../../libs/mysql/cppconn/prepared_statement.h"
#include "../../common/pb/ServerCommon.pb.h"
#include "../../../libs/jemalloc/jemalloc.h"
#include "../../common/CommDefine.h"

extern std::queue<Task> gQueue;
extern std::mutex gMutex;
extern std::unordered_map<int64_t, TcpConnecter *> gClients;

MainThread::~MainThread()
{
}

void MainThread::start(uint16_t port)
{

	tcp_.start(port, ConType::ConType_db_server);

	logInfo("------------------------------dbserver start------------------------------");
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

			if (t.opt_ == ConType::ConType_timer && t.func_)
			{
				t.func_(t.args_);
				if (t.args_ && t.timerRepeated_ == 0)
				{
					je_free(t.args_);
				}
			}
			else
			{
				processClientMessage(t);
			}

			if (t.data_)
			{
				je_free(t.data_);
			}

			qt_.pop();
		}

		if (quit_.load(std::memory_order_relaxed))
		{
			logQuit("--------------db quit success------------");
			break;
		}
	}
}

void MainThread::processClientMessage(Task &t)
{
	//logInfo("processClientMessage");
	if(t.data_ && t.len_ > 0)
	{
		uint16_t messageId = 0;
		memcpy(&messageId, t.data_, 2);
		dispatchClientMessage(messageId, t.sessionId_, t.data_ + 2, t.len_ - 2);
	}

}

void MainThread::closeServer()
{
	logInfo("recv game close process message");
	gTimer.closeTimer();
	tcp_.quitIoLoop();

	sleep(2);
	quit_.store(true, std::memory_order_relaxed);
	Task t;
	std::unique_lock<std::mutex> lk(gMutex);
	gQueue.emplace(std::move(t));
	gCondVar.notify_one();
}
