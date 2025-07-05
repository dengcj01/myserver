
#pragma once
#include <stdint.h>
#include <pthread.h>
#include <thread>
#include <list>
#include <unistd.h>
#include <queue>
#include <unordered_map>
#include <string>
#include <string.h>
#include <atomic>
#include <iostream>
#include "net/Data.h"
#include "Singleton.h"
#include "log/Log.h"
#include "../../libs/jemalloc/jemalloc.h"
#include "CommDefine.h"

extern std::queue<Task> gQueue;
extern std::mutex gMutex;
extern std::condition_variable gCondVar;

using pf = void (*)(Args *);

struct TimerTask
{
	TimerTask() {}
	TimerTask(std::string tid, pf func, uint32_t expire, uint8_t wheelCnt, Args *agrs = nullptr, uint8_t opt = 0) : tid_(tid),
																												func_(func),
																												expire_(expire),
																												wheelCnt_(wheelCnt),
																												args_(agrs),
																												opt_(opt)

	{
	}

	std::string tid_;	// 定时器id
	pf func_ = nullptr;		// 回调函数
	uint32_t expire_ = 0;	// 过期时间
	uint8_t wheelCnt_ = 0; // 这个任务需要转几圈
	Args *args_;			// 传递给任务的参数
	uint8_t opt_ = 0;		// 是否重复执行
};

const uint16_t constSlotCnt = 256;					// 槽大小
const uint16_t constSlotCntBack = constSlotCnt - 1; // 槽大小
const uint8_t constBase = 8;

class Timer : public Singleton<Timer>
{
public:
	~Timer()
	{

	}

	void closeTimer()
	{
		running_ = false;
	}
	
	void lock()
	{
		pthread_spin_lock(&sp_);
	}

	void unlock()
	{
		pthread_spin_unlock(&sp_);		
	}

	void init()
	{
		pthread_spin_init(&sp_, PTHREAD_PROCESS_PRIVATE);
		for (int i = 0; i < constSlotCnt; i++)
		{
			slots_[i] = std::unordered_map<std::string, TimerTask>();
		}

		timerThread_ = std::thread(&Timer::update, this);
		timerThread_.detach();
		// logInfo("------------------------timer start success ------------------------");
	}

	void addNext(TimerTask &t, uint16_t idx)
	{
		uint32_t endTime = t.expire_ + idx;
		uint16_t slotIdx = endTime & constSlotCntBack;
		t.wheelCnt_ = endTime >> constBase;
		auto &head = slots_[slotIdx];
		std::string tid = t.tid_;
		head.emplace(tid, TimerTask(std::move(t)));

		auto it = cacheTid_.find(tid);
		if (it != cacheTid_.end())
		{
			cacheTid_[tid] = slotIdx;
		}
	}

	void update()
	{
		while (running_.load())
		{
			lock();
			auto &head = slots_[idx_];
			for (auto it = head.begin(); it != head.end();)
			{
				auto &t = it->second;
				bool luaf = false;

				if(t.args_ && t.args_->lua_)
				{
					luaf = true;
				}

				if ((t.func_ || luaf) && t.wheelCnt_ == 0)
				{

					Task tk;
					if (luaf)
					{
						memset(t.args_->tid_, 0, 20);
						strcpy(t.args_->tid_, it->first.c_str());
					}


					tk.args_ = t.args_;
					tk.func_ = t.func_;
					tk.opt_ = ConType::ConType_timer;
					tk.timerRepeated_ = t.opt_;

					std::unique_lock<std::mutex> lk(gMutex);
					gQueue.emplace(std::move(tk));
					gCondVar.notify_one();
					
					auto copyt = t;
					it = head.erase(it++);

					if (t.opt_ == 1)
					{
						addNext(copyt, idx_);
					}
				}
				else
				{
					it++;
				}
			}

			unlock();

			sleep(1);

			lock();

			if (++idx_ >= constSlotCnt)
			{
				idx_ = 0;

				for (int i = 0; i < constSlotCnt; i++)
				{
					auto &slot = slots_[i];
					for (auto it = slot.begin(); it != slot.end(); it++)
					{
						auto &t = it->second;
						if (t.wheelCnt_ > 0)
						{
							t.wheelCnt_--;
						}
					}
				}
			}
			unlock();

		}


		logInfo("-----------------------------------timer quit success ------------------------");
	}

	std::string add(uint32_t expire, pf func, Args *args = nullptr, uint8_t opt = 0) // opt是否重复执行0不是1是
	{
		if (expire <= 0)
		{
			logInfo("expire err");
			return "";
		}


		lock();
		int endTime = expire + idx_;

		int slotIdx = endTime & constSlotCntBack;
		int wheelCnt = expire >> constBase;
		auto &head = slots_[slotIdx];

		std::string tid = std::to_string(gtid);
		const char *stid = tid.c_str();

		head.emplace(tid, TimerTask(stid, func, expire, wheelCnt, args, opt));

		auto it = cacheTid_.find(tid);
		if (it == cacheTid_.end())
		{
			cacheTid_.emplace(tid, slotIdx);
		}

		unlock();

		gtid++;


		return tid;
	}

	void del(const char *sid)
	{
		std::string tid = sid;

		lock();
		auto it = cacheTid_.find(tid);
		if (it == cacheTid_.end())
		{
			unlock();
			return;
		}
		
		uint16_t idx = it->second;
		
		cacheTid_.erase(it);

		auto &head = slots_[idx];

		auto itt = head.find(tid);
		if (itt != head.end())
		{
			TimerTask &obj = itt->second;
			if (obj.args_)
			{
				free(obj.args_);
				obj.args_ = nullptr;
			}
			head.erase(itt);
		}

		unlock();
	}

	std::string updateTime(const char *sid, uint32_t expire, pf func, Args *args = nullptr, uint8_t opt = 0)
	{
		del(sid);
		return add(expire, func, args, opt);
	}

public:
	std::atomic<bool> running_{true};

private:
	int idx_ = 0;
	int64_t gtid = 1;
	std::unordered_map<std::string, TimerTask> slots_[constSlotCnt];
	std::thread timerThread_;
	std::unordered_map<std::string, uint16_t> cacheTid_;
	pthread_spinlock_t sp_;
};

#define gTimer Timer::instance()