

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
//#include "../../../libs/jemalloc/jemalloc.h"
#include "../../common/CommDefine.h"

extern std::queue<Task> gQueue;
extern std::mutex gMutex;


MainThread::~MainThread()
{
}

uint8_t MainThread::getDbKeyType(uint64_t pid, const char* key)
{
	auto it = dbKey_.find(key);
	if(it == dbKey_.end())
	{
		logInfo("no reg key %llu %s", pid, key);
		return 0;
	}

	return it->second;
}

void MainThread::start(uint16_t port)
{
	dbKey_.emplace("name", OfflineDbKeyDef::OfflineDbKeyDefString);
	dbKey_.emplace("icon", OfflineDbKeyDef::OfflineDbKeyDefString);	
	dbKey_.emplace("power", OfflineDbKeyDef::offlinedbkeydefint64);
	dbKey_.emplace("level", OfflineDbKeyDef::OfflineDbKeyDefInt);	
	dbKey_.emplace("headicon", OfflineDbKeyDef::OfflineDbKeyDefInt);
	dbKey_.emplace("title", OfflineDbKeyDef::OfflineDbKeyDefInt);	
	dbKey_.emplace("skin", OfflineDbKeyDef::OfflineDbKeyDefInt);
	dbKey_.emplace("bantime", OfflineDbKeyDef::offlinedbkeydeftime);	
	dbKey_.emplace("banreason", OfflineDbKeyDef::OfflineDbKeyDefString);
	dbKey_.emplace("guildid", OfflineDbKeyDef::offlinedbkeydefint64);
	dbKey_.emplace("serverid", OfflineDbKeyDef::OfflineDbKeyDefInt);
	dbKey_.emplace("logouttime", OfflineDbKeyDef::offlinedbkeydeftime);


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
					free(t.args_);
				}
			}
			else
			{
				processClientMessage(t);
			}

			if (t.data_)
			{
				free(t.data_);
			}

			qt_.pop();
		}

		if (quit_.load())
		{
			logQuit("--------------db quit success------------");
			break;
		}
	}
}

void MainThread::processClientMessage(Task &t)
{

	if(t.data_ && t.len_ > 0)
	{
		uint16_t messageId = 0;
		memcpy(&messageId, t.data_, 2);
		messageId = ntohs(messageId);


		dispatchClientMessage(messageId, t.sessionId_, t.data_ + 2, t.len_ - 2);
	}

}

void MainThread::closeServer()
{
	logInfo("开始关闭缓存服务器");

	tcp_.quitIoLoop();

	sleep(1);
	quit_ = true;
	
	Task t;
	std::unique_lock<std::mutex> lk(gMutex);
	gQueue.emplace(std::move(t));
	gCondVar.notify_one();
}
