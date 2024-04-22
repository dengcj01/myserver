
#include "TcpServer.h"

#include <sys/syscall.h>
#include <unistd.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <string>
#include <algorithm>
#include <condition_variable>

#include "../../../libs/jemalloc/jemalloc.h"
#include "../ParseConfig.hpp"

#include "../log/Log.h"
#include "EventLoop.h"
#include "TcpConnecter.h"
#include "Data.h"

#include "../Client.h"

std::unordered_map<int64_t, TcpConnecter *> gClients;
pthread_spinlock_t gsp;
extern std::mutex gMutex;
extern std::queue<Task> gQueue;
extern std::condition_variable gCondVar;
extern std::unordered_map<uint8_t, Client *> gServerClients;

TcpServer::TcpServer()
{
}

TcpServer::~TcpServer()
{
	if (mainChanel_)
	{
		delete mainChanel_;
		mainChanel_ = nullptr;
	}

	if (mainEventLoop_)
	{
		delete mainEventLoop_;
		mainEventLoop_ = nullptr;
	}
}

void TcpServer::init(uint16_t port)
{
	int fd = (int)socket(AF_INET, SOCK_STREAM, 0);
	if (fd < 0)
	{
		logQuit("create socket err");
		_exit(0);
	}

	fcntl(fd, F_SETFL, fcntl(fd, F_GETFL, 0) | O_NONBLOCK);
	int opt = 1;
	setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, (const char *)&opt, sizeof opt);

	struct sockaddr_in addr;
	addr.sin_port = htons(port);
	addr.sin_family = AF_INET;
	addr.sin_addr.s_addr = htonl(INADDR_ANY);

	socklen_t len = sizeof addr;
	if (bind(fd, (struct sockaddr *)&addr, len) < 0)
	{
		logQuit("bind sockaddr err %d", errno);
		_exit(0);
	}

	if (listen(fd, SOMAXCONN) < 0)
	{
		logQuit("listen err");
		_exit(0);
	}

	mainChanel_ = new Channel(fd);
	mainEventLoop_ = new EventLoop();
	mainEventLoop_->updateEvent(mainChanel_);
	mainChanel_->setReadCb(std::bind(&TcpServer::acceptClient, this));

	pthread_spin_init(&sp_, PTHREAD_PROCESS_PRIVATE);
	pthread_spin_init(&gsp, PTHREAD_PROCESS_PRIVATE);
}

void TcpServer::start(uint16_t port, uint8_t mod, bool cmd)
{
	mod_ = mod;
	init(port);
	mainThread_ = std::move(std::thread([&]()
										{ mainEventLoop_->startLoop("main"); }));

	if (cmd)
	{
		cmdThread_ = std::move(std::thread([&]()
										   {
			while (true)
			{
				if (cmdQuit_.load(std::memory_order_relaxed))
				{
					break;
				}

				std::string buf;
				std::getline(std::cin, buf);
				Task task;
				task.opt_ = 0;
				task.cmd_ = buf;
				if(buf.size()>0)
				{
					std::unique_lock<std::mutex> lk(gMutex);
					gQueue.emplace(std::move(task));
					lk.unlock();
					gCondVar.notify_one();
				}
			} }));
		cmdThread_.detach();
	}

	uint8_t threadCnt = std::thread::hardware_concurrency();
	uint8_t ioCnt = std::max(threadCnt, (uint8_t)4);
	for (uint8_t i = 0; i < ioCnt; ++i)
	{
		threadPool_.emplace_back(std::thread(&TcpServer::initWorkThread, this, mod_));
	}
}

void TcpServer::initWorkThread(uint8_t mod)
{
	EventLoop evevtLoop;
	evevtLoop.setMod(mod);
	pthread_spin_lock(&sp_);
	workLoops_.emplace_back(&evevtLoop);
	pthread_spin_unlock(&sp_);
	evevtLoop.startLoop("io");
}

void TcpServer::acceptClient()
{
	EventLoop *loop = nullptr;
	if (workLoops_.size() <= 0)
	{
		loop = mainEventLoop_;
	}
	else
	{
		loop = workLoops_[loopIndex_++];
		if (loopIndex_ >= (workLoops_.size()))
		{
			loopIndex_ = 0;
		}
	}

	struct sockaddr_in addr;
	socklen_t len = sizeof(addr);
	int listenFd = mainChanel_->getFd();
	int cliFd = accept(listenFd, (struct sockaddr *)&addr, &len);
	if (cliFd < 0)
	{
		logInfo("accept err errno:%d", errno);
		return;
	}

	fcntl(cliFd, F_SETFL, fcntl(cliFd, F_GETFL, 0) | O_NONBLOCK);
	TcpConnecter *con = new TcpConnecter(cliFd, ++sessionId_, loop);
	con->init();
	con->setIpAndPort(inet_ntoa(addr.sin_addr), ntohs(addr.sin_port));
	con->setCloseCb(std::bind(&TcpServer::closeClient, this, std::placeholders::_1));
	con->setMod(mod_);

	pthread_spin_lock(&gsp);
	gClients.emplace(sessionId_, con);
	pthread_spin_unlock(&gsp);

	logInfo("acceptClient ip:%s port:%d:sessionId:%llu", inet_ntoa(addr.sin_addr), ntohs(addr.sin_port), sessionId_);
}

void TcpServer::closeClient(uint64_t sessionId)
{
	logInfo("closeClient sessionId:%llu", sessionId);
	TcpConnecter *con = nullptr;

	pthread_spin_lock(&gsp);
	auto it = gClients.find(sessionId);
	if (it == gClients.end())
	{
		logInfo("closeClient no find this client %llu", sessionId);
		pthread_spin_unlock(&gsp);
		return;
	}

	con = it->second;
	gClients.erase(it);
	pthread_spin_unlock(&gsp);

	const char *ip = con->getIp();
	uint8_t opt = con->getMod();
	delete con;
	con = nullptr;

	Task t;
	t.opt_ = opt;
	t.sessionId_ = sessionId;
	t.close_ = true;
	t.ip_ = ip;

	std::unique_lock<std::mutex> lk(gMutex);
	gQueue.push(std::move(t));
	lk.unlock();
	gCondVar.notify_one();
}

void TcpServer::sendMessage2Game(Task &t)
{
	TcpConnecter *con = nullptr;
	pthread_spin_lock(&gsp);
	auto it = gClients.find(t.sessionId_);
	if (it == gClients.end())
	{
		logInfo("sendMessage2Game no find this client, sessionId = %llu", t.sessionId_);
		pthread_spin_unlock(&gsp);
		return;
	}

	con = it->second;
	pthread_spin_unlock(&gsp);

	EventLoop *loop = con->getEventLoop();
	loop->addMessage(t);
	loop->weakUp();
}

void TcpServer::quitIoLoop()
{

	mainEventLoop_->quit_.store(true, std::memory_order_relaxed);
	mainEventLoop_->weakUp();

	mainThread_.join();
	for (auto it = workLoops_.begin(); it != workLoops_.end(); it++)
	{
		EventLoop *loop = (*it);
		loop->quit_.store(true, std::memory_order_relaxed);
		loop->weakUp();
	}

	for (auto it = threadPool_.begin(); it != threadPool_.end(); it++)
	{
		(*it).join();
	}
}

void TcpServer::sendMessage2DbServer(Task &t)
{
	uint8_t cliType = (uint8_t)ConType::ConType_db_client;
	auto it = gServerClients.find(cliType);
	if (it != gServerClients.end())
	{
		it->second->sendMessage2Server(t);
	}
}

void TcpServer::sendMessage2LogServer(Task &t)
{
	uint8_t cliType = (uint8_t)ConType::ConType_log_client;
	auto it = gServerClients.find(cliType);
	if (it != gServerClients.end())
	{
		it->second->sendMessage2Server(t);
	}
}

void TcpServer::sendMessage2MasterServer(Task &t)
{
	uint8_t cliType = (uint8_t)ConType::ConType_game_client;
	auto it = gServerClients.find(cliType);
	if (it != gServerClients.end())
	{
		it->second->sendMessage2Server(t);
	}
}

bool TcpServer::conExists(uint64_t sessionId)
{
	pthread_spin_lock(&gsp);
	auto it = gClients.find(sessionId);
	if (it == gClients.end())
	{
		pthread_spin_unlock(&gsp);
		return false;
	}

	pthread_spin_unlock(&gsp);
	return true;
}

uint64_t TcpServer::getSessionId()
{
	pthread_spin_lock(&gsp);
	for (auto it = gClients.begin(); it != gClients.end(); it++)
	{
		pthread_spin_unlock(&gsp);
		return it->first;
	}

	pthread_spin_unlock(&gsp);
	return 0;
}

void TcpServer::forceCloseSession(uint64_t sessionId)
{
	pthread_spin_lock(&gsp);
	TcpConnecter *con = 0;
	auto it = gClients.find(sessionId);
	if (it == gClients.end())
	{
		logInfo("forceCloseSession err, no find messageId = %llu", sessionId);
		pthread_spin_unlock(&gsp);
		return;
	}
	con = it->second;
	pthread_spin_unlock(&gsp);
	EventLoop *loop = con->getEventLoop();
	loop->addRemoveList(con->getSessionId());
	loop->weakUp();
}

void TcpServer::forceCloseAllSession()
{
	pthread_spin_lock(&gsp);
	std::map<EventLoop *, std::vector<uint64_t>> tmp;
	for (auto e : gClients)
	{
		TcpConnecter *con = e.second;
		EventLoop *loop = con->getEventLoop();
		auto it = tmp.find(loop);
		if (it == tmp.end())
		{
			std::vector<uint64_t> v;
			v.emplace_back(con->getSessionId());
			tmp.emplace(loop, std::move(v));
		}
		else
		{
			std::vector<uint64_t> &v = it->second;
			v.emplace_back(con->getSessionId());
		}
	}
	pthread_spin_unlock(&gsp);

	//logInfo("forceCloseAllSession %d",tmp.size());

	for (auto e : tmp)
	{
		EventLoop *loop = e.first;
		for (auto sid : e.second)
		{
			loop->addRemoveList(sid);
		}
		loop->weakUp();
	}
}