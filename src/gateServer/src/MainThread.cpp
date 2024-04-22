

#include "MainThread.h"
#include <atomic>
#include <pthread.h>
#include <chrono>
#include <unistd.h>
#include <sstream>
#include <iostream>
#include <regex>
#include <sys/syscall.h>
#include <algorithm>
#include <iostream>
#include <fstream>

#include "../../common/net/EventLoop.h"
#include "../../common/net/TcpConnecter.h"
#include "../../common/Timer.hpp"
#include "../../common/log/Log.h"
#include "../../common/CommDefine.h"
#include "../../common/Client.h"
#include "../../common/ParseConfig.hpp"
#include "../../../libs/jemalloc/jemalloc.h"

extern std::unordered_map<int64_t, TcpConnecter *> gClients;
extern pthread_spinlock_t gsp;
extern std::mutex gMutex;
extern std::queue<Task> gQueue;
extern std::condition_variable gCondVar;
extern std::unordered_map<uint8_t, Client *> gServerClients;

MainThread::~MainThread()
{
}

void MainThread::initClient()
{
	for(uint8_t i = ConType::ConType_client_gate1; i<= ConType::ConType_client_gate4; i++)
	{
		gServerClients.emplace(i, new Client());
		Client *cli = gServerClients[i];
		cli->init(i, gParseConfig.gamePort_, "127.0.0.1");
	}

}

void MainThread::start(uint16_t port)
{
	initClient();
	{
		uint8_t mod = ConType::ConType_gate_server;
		tcp_.start(port, mod);
		logInfo("-------------------start %s server success ------------------------", gParseConfig.name_.data());
	}

	while (isRunning_)
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
		//logInfo("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx %d", qt_.size());

		if (quit_.load(std::memory_order_relaxed))
		{
			logQuit("------------------------quit  gate  success------------");
			break;
		}

		while (!qt_.empty())
		{
			Task &t = qt_.front();
			//logInfo("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx11 %d", t.opt_);

			uint8_t opt = t.opt_;
			if (opt == ConType::ConType_gate_server)
			{
				forward2GameServer(t.data_, t.len_, t.sessionId_, t.close_ == true ? 1 : 0);
			}
			else if (opt == ConType::ConType_client_gate1 ||
					opt == ConType::ConType_client_gate2 ||
					opt == ConType::ConType_client_gate3 ||
					opt == ConType::ConType_client_gate4)
			{
				processGameServerMessage(t);
			}
			else if (opt == ConType::ConType_timer)
			{
				if (t.func_)
				{
					t.func_(t.args_);
					if (t.args_ && t.timerRepeated_ == 0)
					{
						je_free(t.args_);
					}
				}
			}
			if (t.data_)
			{
				je_free(t.data_);
			}

			qt_.pop();
		}
	}
}



void MainThread::processGameServerMessage(Task &t)
{
	//logInfo("processGameServerMessage");
	if (t.gameClose_)
	{
		//logInfo("game server close");
		tcp_.forceCloseAllSession();
	}
	else if (t.data_ && t.len_ > 0)
	{
		char* buf = t.data_;
		uint8_t where = 0;
		memcpy(&where, buf, 1);
		uint64_t csessionId = 0;
		memcpy(&csessionId, buf + 1, 8);
		uint16_t messageId = 0;
		memcpy(&messageId, buf + 9, 2);

		//logInfo("processGameServerMessage %d %d", where, messageId);
		if (messageId == 0)
		{
			closeServer();
			return;
		}

		switch (where)
		{
		case SCCRType::SCCRType_ji_hao:
			tcp_.forceCloseSession(csessionId);
			break;
		
		default:
			break;
		}
	}
}

void MainThread::forward2GameServer(char *data, size_t len, uint64_t sessionId, uint8_t status)
{
	Task tk;
	uint32_t dataLen = len + 8 + 1;
	uint32_t maxLen = dataLen + 4;

	char *buf = (char *)je_malloc(maxLen);
	memcpy(buf, &dataLen, 4);
	memcpy(buf + 4, &status, 1);
	memcpy(buf + 5, &sessionId, 8);
	if (data)
	{
		memcpy(buf + 13, data, len);
	}


	tk.data_ = buf;
	tk.len_ = maxLen;

	Client::getClient()->sendMessage2Server(tk);
	//logInfo("forward2GameServer %d", status);
}

void MainThread::closeServer()
{
	gTimer.closeTimer();
	tcp_.quitIoLoop();

	sleep(2);

	quit_.store(true, std::memory_order_relaxed);
	Task t;
	std::unique_lock<std::mutex> lk(gMutex);
	gQueue.emplace(std::move(t));
	lk.unlock();
	gCondVar.notify_one();
}