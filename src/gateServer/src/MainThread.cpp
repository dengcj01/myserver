

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
#include "../../common/ProtoIdDef.h"
#include "../../common/pb/Login.pb.h"
//#include "../../../libs/jemalloc/jemalloc.h"

extern std::unordered_map<int64_t, TcpConnecter *> gClients;
extern pthread_spinlock_t gsp;
extern std::mutex gMutex;
extern std::queue<Task> gQueue;
extern std::condition_variable gCondVar;
extern std::unordered_map<uint8_t, Client *> gServerClients;
extern std::atomic<bool> gameDumpFlag_;

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
		//uint8_t mod = ConType::ConType_gate_tcp_server;
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

		if (quit_.load())
		{
			break;
		}

		while (!qt_.empty())
		{
			Task &t = qt_.front();
			//logInfo("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx11 %d", t.opt_);

			uint8_t opt = t.opt_;
			if (opt == ConType::ConType_gate_server || opt == ConType::ConType_gate_tcp_server)
			{
				forward2GameServer(t.sessionId_, t.close_ == true ? 1 : 0, t.idx_);
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
						free(t.args_);
					}
				}
			}
			if (t.data_)
			{
				free(t.data_);
			}

			qt_.pop();
		}
	}
	logQuit("------------------------quit  gate  success------------");
}


void MainThread::forward2GameServer(uint64_t sessionId, uint8_t status, uint8_t idx) // 主要处理客户端关闭连接,把消息转给服务器
{
	Task tk;
	uint32_t dataLen = 0 + 8 + 1;
	uint32_t maxLen = dataLen + 4;

	char *buf = (char *)malloc(maxLen);

	uint32_t netLen = ntohl(dataLen);
	memcpy(buf, &netLen, 4);

	memcpy(buf + 4, &status, 1);

	uint64_t nsessionId = htobe64(sessionId);
	memcpy(buf + 5, &nsessionId, 8);


	tk.data_ = buf;
	tk.len_ = maxLen;

	Client* c = gServerClients[idx];
	if(c)
	{
		c->sendMessage2Server(tk);
	}

}

void MainThread::processGameServerMessage(Task &t)
{
	if (t.gameClose_)
	{
		bool ok = false;
		if(gameDumpFlag_.compare_exchange_strong(ok, true))
		{
			logInfo("服务器意外关闭了");
			tcp_.forceCloseAllSession();
		}
	}
	else if (t.data_ && t.len_ > 0)
	{
		char* buf = t.data_;
		uint8_t where = 0;
		memcpy(&where, buf, 1);

		uint64_t csessionId = 0;
		memcpy(&csessionId, buf + 1, 8);
		csessionId = be64toh(csessionId);

		uint16_t messageId = 0;
		memcpy(&messageId, buf + 9, 2);
		messageId = ntohs(messageId);

		logInfo("processGameServerMessage %d %d", where, messageId);
		if(messageId == CoseServer)
		{
			closeServer();
			return;
		}

		if(messageId == (uint16_t)ProtoIdDef::NotifyServerCloseClient) 
		{
			logInfo("服务器强制关了连接 %lu", csessionId);
			TcpServer::forceCloseSession(csessionId, false);
		}
	}
}


void MainThread::closeServer()
{
	logInfo("开始关闭网关服务器...");
	for (auto &e : gServerClients)
	{
		e.second->quit_ = true;
	}

	for (auto &e : gServerClients)
	{
		e.second->quitClient();
	}

	gTimer.closeTimer();

	tcp_.quitIoLoop();
	quit_ = true;


	Task t;
	std::unique_lock<std::mutex> lk(gMutex);
	gQueue.emplace(std::move(t));
	lk.unlock();
	gCondVar.notify_one();
}