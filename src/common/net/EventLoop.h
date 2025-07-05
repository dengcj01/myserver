#pragma once


#include <sys/epoll.h>
#include <vector>
#include <list>
#include <pthread.h>
#include <stdint.h>
#include <string>
#include <atomic>
#include <unordered_map>
#include <mutex>
#include "Data.h"



class Channel;
class TcpConnecter;

class EventLoop
{
public:
	EventLoop();
	//EventLoop(bool isWrite = false);
	~EventLoop();

	void updateEvent(Channel *ch, uint8_t opt = EPOLL_CTL_ADD);
	void startLoop(const char *name);
	void processWeakUpEvent();
	void cleanQueue();
	void weakUp();
	void addWaitList(uint64_t sessionId);

	void lock() { pthread_spin_lock(&sp_); }
	void unlock() { pthread_spin_unlock(&sp_); }
	void setMod(uint8_t mod) { mod_ = mod; }
	void addMessage(Task &t);
	std::string getName() {return name_;}
	void quitLoop();
	size_t getMessageCnt();
	void processWaitDelList(uint64_t sessionId = 0);

public:
	int efd_ = -1;
	uint8_t mod_ = 1; // accept线程标记
	int eventFd_ = -1;
	int eventFd1_ = -1;
	Channel *eventChanel_;
	std::vector<struct epoll_event> eventList_;
	pthread_spinlock_t sp_;
	std::list<Task> queue_;
	std::atomic<bool> quit_{false};
	std::string name_;
	std::mutex mvt_;
	std::unordered_map<uint64_t, uint8_t> waitDelList_; // 强制需要被删除的连接器列表
};
