
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

//#include "../../../libs/jemalloc/jemalloc.h"
#include "../ParseConfig.hpp"
#include "../Tools.hpp"

#include "../log/Log.h"
#include "EventLoop.h"
#include "TcpConnecter.h"
#include "Data.h"
#include "../Timer.hpp"

#include "../Client.h"
#include "../../../libs/readline/readline.h"
#include "../../../libs/readline/history.h"

std::unordered_map<int64_t, TcpConnecter *> gClients;
//pthread_spinlock_t writeGsp;

pthread_spinlock_t gsp;
extern std::mutex gMutex;
extern std::queue<Task> gQueue;
extern std::condition_variable gCondVar;
extern std::unordered_map<uint8_t, Client *> gServerClients;
extern std::mutex cliMtx;
extern std::atomic<bool> cmdStopFlag;

std::mutex gLoopTex_;
std::unordered_map<int64_t, EventLoop *> gLoops;

std::atomic<bool> gateDumpFlag_{false};

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
	setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

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
	//pthread_spin_init(&writeGsp, PTHREAD_PROCESS_PRIVATE);
	//logInfo("listten fd:%d", fd);
}

void TcpServer::start(uint16_t port, uint8_t mod, bool cmd)
{
	mod_ = mod;
	init(port);
	mainThread_ = std::thread([&]()
										{ mainEventLoop_->startLoop("accept"); });

	if (cmd)
	{
		using_history();
		cmdThread_ = std::thread([&]()
										   {
			while (cmdStopFlag.load())
			{
				char* input = readline("");
				Task task;
				task.opt_ = ConType::ConType_cmd;

				if(input[0] == '\0')
				{
					task.cmd_ = "\n";
					free(input);
				}
				else
				{
					task.cmd_ = input;
					add_history(input);
					free(input);
				}

				std::unique_lock<std::mutex> lk(gMutex);
				gQueue.emplace(std::move(task));
				lk.unlock();
				gCondVar.notify_one();
			} });
		cmdThread_.detach();
	}

	uint8_t threadCnt = std::thread::hardware_concurrency();
	uint8_t ioCnt = std::max(threadCnt, (uint8_t)4);
	if(mod_ == ConType_db_server)
	{
		ioCnt = 1;
	}
	ioCnt = 1;
	for (uint8_t i = 0; i < ioCnt; ++i)
	{
		threadPool_.emplace_back(std::thread(&TcpServer::initWorkThread, this, mod_, i));
		usleep(10000);
	}
}

void TcpServer::initWorkThread(uint8_t mod, uint8_t idx)
{
	EventLoop evevtLoop;
	evevtLoop.setMod(mod);
	pthread_spin_lock(&sp_);
	workLoops_.emplace_back(&evevtLoop);
	pthread_spin_unlock(&sp_);
	std::string s = std::to_string(idx);
	s+="io";
	evevtLoop.startLoop(s.c_str());
}

uint8_t TcpServer::getClientIdx()
{
	uint8_t idx = idx_;
	if(++idx_ > ConType_client_gate4)
	{
		idx_ = ConType_client_gate1; 
	}
	return idx; 
	//return idx_;
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
	if(!con->mallocOk())
	{	
		delete con;
		close(cliFd);
		logInfo("accept malloc err");
		return;
	}

	const char* ip = inet_ntoa(addr.sin_addr);
	con->setIpAndPort(ip, ntohs(addr.sin_port));
	con->setCloseCb(std::bind(&TcpServer::closeClient, std::placeholders::_1, std::placeholders::_2));
	con->setMod(mod_);
	con->init();
	const std::string name = loop->getName();
	con->setLoopName(name);

	if(mod_ == ConType_gate_tcp_server || mod_ == ConType_gate_server)
	{
		con->setIdx(getClientIdx());
	}

	if(mod_ == ConType_game_server)
	{
		gateDumpFlag_ = false;
	}

	addLoop(sessionId_, loop);

	pthread_spin_lock(&gsp);
	gClients.emplace(sessionId_, con);
	pthread_spin_unlock(&gsp);


	logInfo("acceptClient sess:%llu cliidx:%d name:%s fd:%d errno:%d %s", sessionId_, con->getIdx(), name.data(), cliFd, errno, ip);
}

void TcpServer::closeClient(uint64_t sessionId, bool notice)
{
	TcpConnecter *con = nullptr;
	pthread_spin_lock(&gsp);
	auto it = gClients.find(sessionId);
	if (it == gClients.end())
	{
		pthread_spin_unlock(&gsp);
		return;
	}
	con = it->second;
	gClients.erase(it);
	pthread_spin_unlock(&gsp);

	logInfo("closeClientcloseClientcloseClient %lu %d", sessionId, notice);

	delLoop(sessionId);

	uint8_t idx = con->getIdx();
	Channel* ch = con->getChannel();
	EventLoop *loop = con->getEventLoop();

	uint8_t opt = 0;
	if(gParseConfig.isGateServer())
	{
		//opt = ConType_gate_tcp_server;
		opt = ConType_gate_server;

		if(!con->heart_.empty())
		{
			gTimer.del(con->heart_.data());
		}

		if(loop)
		{
			loop->processWaitDelList(sessionId);
		}
	}

	if(ch && loop)
	{
		int fd = ch->getFd();
		loop->updateEvent(ch, EPOLL_CTL_DEL);
		close(fd);
	}

	delete con;
	con = nullptr;

	if(gParseConfig.isDbServer())
	{
		return;		
	}
	

	if(gParseConfig.isGameServer())
	{
		opt = ConType_game_server;
	}


	if(notice)
	{	
		if(gParseConfig.isGameServer())
		{
			bool ok = false;
			if(gateDumpFlag_.compare_exchange_strong(ok, true))
			{
				Task t;
				t.opt_ = opt;
				t.sessionId_ = sessionId;
				t.close_ = true;
				t.idx_ = idx;
		
		
				std::unique_lock<std::mutex> lk(gMutex);
				gQueue.emplace(std::move(t));
				lk.unlock();
				gCondVar.notify_one();
			}
		}
		else
		{
			Task t;
			t.opt_ = opt;
			t.sessionId_ = sessionId;
			t.close_ = true;
			t.idx_ = idx;
	
	
			std::unique_lock<std::mutex> lk(gMutex);
			gQueue.emplace(std::move(t));
			lk.unlock();
			gCondVar.notify_one();
		}
	}
}

void TcpServer::sendMessage2Game(Task &t)
{

	EventLoop *loop = getLoop(t.sessionId_);
	if(loop)
	{
		loop->addMessage(t);
		loop->weakUp();
	}
	else
	{
		logInfo("sendMessage2Game err");
	}

}

void TcpServer::quitIoLoop()
{

	mainEventLoop_->quit_ = true;
	mainEventLoop_->weakUp();

	mainThread_.join();
	for (auto it = workLoops_.begin(); it != workLoops_.end(); it++)
	{
		EventLoop *loop = (*it);
		loop->quit_ = true;
		loop->weakUp();
	}

	for (auto it = threadPool_.begin(); it != threadPool_.end(); it++)
	{
		(*it).join();
	}
}

void TcpServer::sendMessage2HttpServer(Task &t)
{
	uint8_t cliType = (uint8_t)ConType::ConType_http_client;
	auto it = gServerClients.find(cliType);
	if (it != gServerClients.end())
	{
		it->second->sendMessage2Server(t);
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

void TcpServer::forceCloseSession(uint64_t sessionId, bool notice)
{
	if(notice)
	{
		closeClient(sessionId, notice);
	}
	else
	{
		TcpConnecter *con = 0;

		pthread_spin_lock(&gsp);
		auto it = gClients.find(sessionId);
		if (it == gClients.end())
		{
			pthread_spin_unlock(&gsp);
			return;
		}
		con = it->second;
		pthread_spin_unlock(&gsp);

		con->setFinCloseFlag();

		EventLoop* loop = con->getEventLoop();
		if(loop)
		{
			loop->addWaitList(sessionId);
			loop->weakUp(); // 唤醒epoll, 让其自然删除对象
		}


	}
}

void TcpServer::forceCloseAllSession()
{
	std::vector<uint64_t> tmp;
	pthread_spin_lock(&gsp);
	for (auto e : gClients)
	{
		tmp.emplace_back(e.first);
	}
	pthread_spin_unlock(&gsp);

	for (auto e : tmp)
	{
		forceCloseSession(e, false);
	}
}

void TcpServer::headTickCallback(Args* args)
{	
	uint64_t sessionId = args->csessionId;
	logInfo("-----------------心跳包超时服务器强制关了客户端连接 %llu", sessionId);
	forceCloseSession(sessionId);

}

void TcpServer::addLoop(uint64_t sessionId, EventLoop* loop)
{
	std::unique_lock<std::mutex> lk(gLoopTex_);
	gLoops.emplace(sessionId, loop);
	lk.unlock();
}

void TcpServer::delLoop(uint64_t sessionId)
{
	std::unique_lock<std::mutex> lk(gLoopTex_);
	gLoops.erase(sessionId);
	lk.unlock();
}

EventLoop* TcpServer::getLoop(uint64_t sessionId)
{	
	std::unique_lock<std::mutex> lk(gLoopTex_);
	auto it = gLoops.find(sessionId);
	if(it == gLoops.end())
	{
		lk.unlock();
		return nullptr;
	}

	EventLoop* l = it->second;
	lk.unlock();

	return l;
}

EventLoop* TcpServer::randLoop()
{	
	std::unique_lock<std::mutex> lk(gLoopTex_);
	for(auto it = gLoops.begin(); it!= gLoops.end(); it++)
	{
		return it->second;
	}

	return nullptr;
}


