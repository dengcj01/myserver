
#pragma once
#include <stdio.h>
#include <vector>
#include <string>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <atomic>
#include <tuple>
#include <chrono>

#include "../Singleton.h"

class Log : public Singleton<Log>
{
public:
	~Log();

public:
	void writeLogThreadFunc();
	void init(const char *pathName, const char* name);
	void quit(const char *fileName, int line, const char *fmt, ...);
	void info(const char *fileName, int line, const char *fmt, ...);


private:

	// int fd_;
	void timeChange(int& year, int& month, int& day);

	std::string pathName_;
	std::string name_;

	FILE *pf_;
	int year_;
	int month_;
	int day_;

	std::thread logThread_;
	std::vector<std::string> vecLog_;
	std::mutex mutex_;
	std::mutex fileMutex_;
	std::condition_variable cond_;
	std::atomic<bool> quitFlag_{false};
};

#define logInit(path, name) Log::instance().init(path, name)
#define logInfo(fmt, ...) Log::instance().info(__FILE__, __LINE__, fmt, ##__VA_ARGS__)
#define logQuit(fmt, ...) Log::instance().quit(__FILE__, __LINE__, fmt, ##__VA_ARGS__)

