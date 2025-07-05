#pragma once

// #include <condition_variable>
// #include <mutex>
// #include <queue>
#include <string>
#include <stdint.h>

class TcpConnecter;
class EventLoop;

struct Args
{
	void* obj_=0;
	bool first_=false;
	int fd_;
	char luaFunc_[15] = {};
	uint64_t pid_ = 0;
	uint64_t sessionId = 0;
	uint64_t csessionId = 0;
	char tid_[20]={};
	bool lua_=false;
	char rankName_[50] = {};

};

using pf = void(*)(Args*);


struct Task
{
	Task(char* data = nullptr, uint32_t len = 0, uint8_t opt = 1, pf func = nullptr):
		data_(data),
		len_(len),
		opt_(opt),
		func_(func)
		{

		}	
	char *data_ = nullptr;
	uint64_t len_ =0;
	uint8_t opt_=1;
	uint8_t idx_=0;
	pf func_ = nullptr;
	Args *args_ = nullptr;
	bool close_ = false;
	bool connect_=false;
	bool gameClose_ = false;
	uint64_t sessionId_ = 0;
	std::string cmd_="";
	uint8_t timerRepeated_ = 0; // 定时器重复标记
	std::string ip_=""; // 客户端ip
	bool fightRes = false; // 战斗结果
	TcpConnecter* con_=0;
	bool todb_=false;
};
