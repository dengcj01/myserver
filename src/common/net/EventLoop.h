#pragma once

#include <sys/epoll.h>
#include <vector>
#include <queue>
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
	~EventLoop();

	void updateEvent(Channel *ch, uint8_t opt = 1);
	void startLoop(const char *name);
	void processWeakUpEvent();
	void cleanQueue();
	void weakUp();
	void addRemoveList(uint64_t sessionId);

	inline void lock() { pthread_spin_lock(&sp_); }
	inline void unlock() { pthread_spin_unlock(&sp_); }
	inline void setMod(uint8_t mod) { mod_ = mod; }
	void addMessage(Task &t);
	bool checkMessageProcessEnd(uint64_t sessionId);

public:
	int efd_ = -1;
	uint8_t mod_ = 1; 
	int eventFd_ = -1;
	Channel *eventChanel_;
	std::vector<struct epoll_event> eventList_;
	std::vector<uint64_t> vecSessiond_;
	pthread_spinlock_t sp_;
	std::queue<Task> queue_;
	std::atomic<bool> quit_{false};
	std::string name_;
	std::mutex mvt_;
};
