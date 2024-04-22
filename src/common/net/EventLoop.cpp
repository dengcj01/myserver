

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

#include "../../../libs/jemalloc/jemalloc.h"
#include "../ParseConfig.hpp"

extern pthread_spinlock_t gsp;
extern std::unordered_map<int64_t, TcpConnecter *> gClients;
extern std::unordered_map<uint8_t, Client *> gServerClients;

/*
#define EPOLL_CTL_ADD 1
#define EPOLL_CTL_DEL 2
#define EPOLL_CTL_MOD 3
*/

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

	eventChanel_ = new Channel(eventFd_);
	updateEvent(eventChanel_);
	pthread_spin_init(&sp_, PTHREAD_PROCESS_PRIVATE);
}

EventLoop::~EventLoop()
{
	cleanQueue();
}

void EventLoop::updateEvent(Channel *ch, uint8_t opt)
{
	struct epoll_event ev;
	memset(&ev, 0, sizeof(ev));
	ev.events = ch->getEvent();
	ev.data.ptr = ch;
	epoll_ctl(efd_, opt, ch->getFd(), &ev);
}

void EventLoop::startLoop(const char *name)
{

	//logInfo("------------------------start loop %s %d----------------------", name);
	name_ = name;
	while (true)
	{
		int fds = epoll_wait(efd_, &(*eventList_.begin()), (int)eventList_.size(), -1);
		//logInfo("epoll_wait ret cnt=%d name=%s mod=%d quit=%d", fds, name_.c_str(), mod_, quit_.load(std::memory_order_relaxed));
		if (quit_.load(std::memory_order_relaxed))
		{
			//logInfo("--------------loop quit %s------------", name_.c_str());
			break;
		}

		if (fds < 0)
		{
			logInfo("epoll_wait err %d", errno);
		}
		else
		{
			// logInfo("epoll_wait sucess %d", fds);

			for (int i = 0; i < fds; ++i)
			{
				Channel *ch = (Channel *)eventList_[i].data.ptr;
				if (ch->getFd() == eventFd_)
				{
					uint64_t val;
					read(eventFd_, &val, 8);
				}
				else
				{
					ch->setEvent(eventList_[i].events);
					ch->onEvent();
				}
			}

			int count = (int)eventList_.size();
			if (fds == count)
			{
				eventList_.resize(fds * 2);
			}

			// 这里可以优化eventList_占用的内存.暂时没处理

			processWeakUpEvent();

			{
				std::vector<uint64_t> tmp;
				std::unique_lock<std::mutex> lk(mvt_);
				tmp.swap(vecSessiond_);
				lk.unlock();

				for (auto &e : tmp)
				{
					TcpConnecter *con = nullptr;
					pthread_spin_lock(&gsp);
					auto it = gClients.find(e);
					if (it != gClients.end())
					{
						con = it->second;
					}
					pthread_spin_unlock(&gsp);

					if (con)
					{
						con->realClose();
					}
				}
			}
		}
	}
}

void EventLoop::processWeakUpEvent()
{
	std::queue<Task> tmp;
	if (mod_ == ConType::ConType_gate_server ||
		mod_ == ConType::ConType_log_server ||
		mod_ == ConType::conType_game_server ||
		mod_ == ConType::ConType_db_server ||
		mod_ == ConType::ConType_master_server)
	{
		lock();
		while (!queue_.empty())
		{
			tmp.push(std::move(queue_.front()));
			queue_.pop();
		}
		unlock();

		while (!tmp.empty())
		{
			Task &t = tmp.front();

			pthread_spin_lock(&gsp);

			auto it = gClients.find(t.sessionId_);
			if (it == gClients.end())
			{
				if (t.data_)
				{
					je_free(t.data_);
				}

				tmp.pop();
				pthread_spin_unlock(&gsp);
				continue;
			}

			TcpConnecter *con = it->second;
			pthread_spin_unlock(&gsp);

			if (con->isWriteing_)
			{
				return;
			}

			if (con && t.data_ && t.len_ > 0)
			{
				con->nowWrite(t.data_, t.len_);
				je_free(t.data_);
			}

			tmp.pop();
		}
	}
	else
	{
		if (gParseConfig.isGateServer() || gParseConfig.isGameServer())
		{
			Client *c = gServerClients[mod_];
			TcpConnecter *con = c->con_;
			if (!con || con->isWriteing_)
			{
				return;
			}

			lock();
			while (!queue_.empty())
			{
				tmp.push(std::move(queue_.front()));
				queue_.pop();
			}
			unlock();

			while (!tmp.empty())
			{
				Task &t = tmp.front();
				if (con && t.data_ && t.len_ > 0)
				{
					con->nowWrite(t.data_, t.len_);
					je_free(t.data_);
				}

				tmp.pop();
			}
		}
	}
}

void EventLoop::cleanQueue()
{
	lock();
	while (!queue_.empty())
	{
		Task &t = queue_.front();
		if (t.data_)
		{
			je_free(t.data_);
		}
		queue_.pop();
	}
	unlock();
}

void EventLoop::addMessage(Task &t)
{
	lock();
	queue_.emplace(std::move(t));
	unlock();
}

bool EventLoop::checkMessageProcessEnd(uint64_t sessionId)
{
	if (mod_ == ConType::ConType_db_client ||
		mod_ == ConType::ConType_game_client ||
		mod_ == ConType::ConType_log_client ||
		mod_ == ConType::ConType_client_gate1 || 
		mod_ == ConType::ConType_client_gate2 || 
		mod_ == ConType::ConType_client_gate3 || 
		mod_ == ConType::ConType_client_gate4)
	{
		bool ok = false;
		lock();
		ok = queue_.empty();
		unlock();
		return ok;
	}
	else
	{
		lock();
		while (!queue_.empty())
		{
			if (queue_.front().sessionId_ == sessionId)
			{
				unlock();
				return false;
			}
		}
		unlock();
		return true;
	}
}

void EventLoop::weakUp()
{
	uint64_t val = 1;
	write(eventFd_, &val, 8);
}

void EventLoop::addRemoveList(uint64_t sessionId)
{
	std::unique_lock<std::mutex> lk(mvt_);
	vecSessiond_.emplace_back(sessionId);
}