

#include "EventLoop.h"

#include <sys/eventfd.h>
#include <unistd.h>
#include <atomic>
#include <thread>

#include "Channel.h"
#include "../log/Log.h"
#include "TcpConnecter.h"
#include "TcpServer.h"
#include "../Client.h"

//#include "../../../libs/jemalloc/jemalloc.h"
#include "../ParseConfig.hpp"

extern pthread_spinlock_t gsp;
extern std::unordered_map<int64_t, TcpConnecter *> gClients;
extern std::unordered_map<uint8_t, Client *> gServerClients;

/*
#define EPOLL_CTL_ADD 1
#define EPOLL_CTL_DEL 2
#define EPOLL_CTL_MOD 3
*/


void EventLoop::updateEvent(Channel *ch, uint8_t opt)
{
	if(opt == EPOLL_CTL_DEL)
	{
		epoll_ctl(efd_, opt, ch->getFd(), nullptr);
	}
	else
	{
		struct epoll_event ev;
		memset(&ev, 0, sizeof(ev));
		ev.events = ch->getEvent();
		ev.data.ptr = ch;
		epoll_ctl(efd_, opt, ch->getFd(), &ev);
	}
}

EventLoop::EventLoop()
{
	efd_ = epoll_create1(0);
	if (efd_ < 0)
	{
		logQuit("create event loop err");
		_exit(0);
	}


	eventList_.resize(2); // 默认事件数量

	eventFd_ = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
	if (eventFd_ < 0)
	{
		logQuit("create eventFd_ err");
		exit(0);
	}

	eventChanel_ = new Channel(eventFd_, EPOLLIN);
	updateEvent(eventChanel_);
	pthread_spin_init(&sp_, PTHREAD_PROCESS_PRIVATE);
	waitDelList_.reserve(10);
}



EventLoop::~EventLoop()
{
	cleanQueue();

}



void EventLoop::startLoop(const char *name)
{

	logInfo("------------------------start %s loop ----------------------", name);
	name_ = name;
	while (true)
	{	
		int fds = epoll_wait(efd_, &(*eventList_.begin()), (int)eventList_.size(), -1);

		if (quit_.load())
		{
			//logInfo("--------------loop quit %s------------", name_.c_str());
			//logInfo("退出了退出了退出了退出了退出了退出了退出了退出了 %s %d", name_.c_str(), mod_);
			break;
		}

		if (fds < 0)
		{
			logInfo("epoll_wait err %d", errno);
		}
		else
		{
			for (int i = 0; i < fds; ++i)
			{
				struct epoll_event& e = eventList_[i];
				Channel *ch = (Channel *)e.data.ptr;
				if(!ch)
				{
					continue;
				}

				if (ch->getFd() == eventFd_)
				{
					uint64_t val;
					read(eventFd_, &val, 8);
				}
				else
				{
					ch->setEvent(e.events);
					ch->onEvent(mod_);
				}
			}

			int count = (int)eventList_.size();
			if (fds == count)
			{
				eventList_.resize(fds * 2);
			}

			processWeakUpEvent();
		}	

		processWaitDelList();
	}
}

void EventLoop::processWeakUpEvent()
{
	if (mod_ == ConType::ConType_gate_server ||
		mod_ == ConType::ConType_log_server ||
		mod_ == ConType::ConType_game_server ||
		mod_ == ConType::ConType_db_server ||
		mod_ == ConType::ConType_master_server ||
		mod_ == ConType::ConType_gate_tcp_server)
	{
		std::list<Task> tempList;
		std::list<Task> retryList;

		lock();
		tempList.splice(tempList.end(), queue_); 
		unlock();		

		for (auto itor = tempList.begin(); itor != tempList.end();) 
		{
			Task& t = *itor;
			TcpConnecter* con = nullptr;

			pthread_spin_lock(&gsp); 
			auto it = gClients.find(t.sessionId_);
			if (it != gClients.end()) 
			{
				con = it->second;
			}
			pthread_spin_unlock(&gsp);
			

			if (!con) 
			{
				if (t.data_) 
				{
					free(t.data_);
				}

				itor = tempList.erase(itor);
				continue;
			}

			if (con->isWriteing_) 
			{
				retryList.splice(retryList.end(), tempList, itor++);

				continue;
			}


			if (t.data_ && t.len_ > 0)
			{
				con->nowWrite(t.data_, t.len_);
				free(t.data_);
			}
			
			itor = tempList.erase(itor);
		}


		if (!retryList.empty()) 
		{
			lock();
			queue_.splice(queue_.begin(), retryList);
			unlock();
		}


	}
	else
	{
		if (gParseConfig.isGameServer() || gParseConfig.isGateServer() || gParseConfig.isMasterServer()) //game进程的客户端给master/db进程的发消息 主连服给db进程发消息 网关客户端写数据给gameserver进程 
		{
			//logInfo("网关客户端被唤醒了111 mod:%d", mod_);
			Client *c = gServerClients[mod_];
			if(c)
			{
				TcpConnecter *con = c->con_;
				if (!con || con->isWriteing_) 
				{
					//logInfo("处于了写状态了处于了写状态了处于了写状态了处于了写状态了处于了写状态了11111111111111111111 %d", mod_);
					return;
				}


				lock();

				for(auto itor = queue_.begin(); itor != queue_.end();)
				{
					Task& t = *itor;
					if (t.data_ && t.len_ > 0)
					{
						con->nowWrite(t.data_, t.len_, t.todb_);
						free(t.data_);
					}

					itor = queue_.erase(itor);			
					if(con->isWriteing_)
					{
					
						break;
					}	
				}
				unlock();

			}
			else
			{
				logInfo("processWeakUpEvent no client %d", mod_);
			}
			//logInfo("网关客户端被唤醒了222 mod:%d", mod_);

		}
	}
}

void EventLoop::cleanQueue()
{
	lock();
	for(auto itor = queue_.begin(); itor != queue_.end();)	
	{
		Task &t = *itor;
		if (t.data_)
		{
			free(t.data_);
		}
		itor = queue_.erase(itor);

	}
	queue_.clear();

	unlock();
}

void EventLoop::addMessage(Task &t)
{
	lock();
	queue_.emplace_back(std::move(t));
	unlock();
}

void EventLoop::weakUp()
{
	uint64_t val = 1;
	write(eventFd_, &val, 8);
}







void EventLoop::quitLoop()
{
	quit_ = true;
}

size_t EventLoop::getMessageCnt()
{
	size_t cnt = 0;
	lock();
	cnt = queue_.size();
	unlock();
	return cnt;
}

void EventLoop::addWaitList(uint64_t sessionId)
{
	std::unique_lock<std::mutex> lk(mvt_);
	waitDelList_.emplace(sessionId, 1);
}

void EventLoop::processWaitDelList(uint64_t sessionId)
{
	if(sessionId == 0)
	{
		std::unordered_map<uint64_t, uint8_t> tmp;

		{
			std::unique_lock<std::mutex> lk(mvt_);
			tmp = waitDelList_;
			waitDelList_.clear();
		}


		for(auto e: tmp)
		{
			TcpServer::closeClient(e.first, false);
		}

	}
	else
	{
		std::unique_lock<std::mutex> lk(mvt_);
		waitDelList_.erase(sessionId);
	}
	
}

