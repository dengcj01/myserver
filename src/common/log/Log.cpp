

#include "Log.h"

#include <time.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <regex>
#include <unistd.h>
#include <sys/syscall.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <fstream>
#include <sstream>
#include <stdio.h>
#include "../ParseConfig.hpp"

#define log_buf_cache 5097152

void Log::writeLogThreadFunc()
{
	while (true)
	{

		std::vector<std::string> tmp;
		std::unique_lock<std::mutex> lk(mutex_);

		while (vecLog_.empty())
		{
			cond_.wait(lk);
			if (quitFlag_.load())
			{
				break;
			}
		}

		{
			vecLog_.swap(tmp);
			lk.unlock();

			std::stringstream buffer;
			std::unique_lock<std::mutex> fk(fileMutex_);
			if (pf_)
			{
				for (auto &e : tmp)
				{
					buffer << e << "\n";
				}
				fputs(buffer.str().c_str(), pf_);
				fflush(pf_);
			}
			fk.unlock();
		}

		if (quitFlag_.load())
		{
			break;
		}
	}
}

Log::~Log()
{
	if(pf_)
	{
		fclose(pf_);
	}
}

void Log::init(const char *pathName, const char* name)
{
	pathName_ = pathName;
	name_ = name;

	if (access(pathName, 0) != 0)
	{
		mkdir(pathName_.c_str(), S_IRWXU);
	}

	auto now = std::chrono::system_clock::now();
	std::time_t now_t = std::chrono::system_clock::to_time_t(now);
	std::tm *tm = std::localtime(&now_t);

	year_ = tm->tm_year + 1900;
	month_ = tm->tm_mon + 1;
	day_ = tm->tm_mday;


	std::ostringstream oss;
	oss << std::setfill('0') << pathName_<< name_;
	oss << std::setw(4) << year_ << std::setw(2) << month_ << std::setw(2) << day_ << ".log";


	pf_ = fopen(oss.str().c_str(), "a+");
	if (!pf_)
	{
		printf("Log::init err\n");
		perror("reason:");
		abort();
		return;
	}

	logThread_ = std::thread(&Log::writeLogThreadFunc, this);
	logThread_.detach();
}
void Log::timeChange(int& year, int& month, int& day)
{
	if (!pf_)
	{
		return;
	}

	if (year_ == year && month_ == month && day_ == day)
	{
		return;
	}

	std::unique_lock<std::mutex> fk(fileMutex_);
	fclose(pf_);
	pf_ = nullptr;



	std::ostringstream oss;
	oss << std::setfill('0') << pathName_ << name_;
	oss << std::setw(4) << year << std::setw(2) << month << std::setw(2) << day << ".log";

	pf_ = fopen(oss.str().c_str(), "a+");
	if(!pf_)
	{
		fk.unlock();
		return;
	}

	fk.unlock();

	year_ = year;
	month_ = month;
	day_ = day;

	return;
}


void Log::info(const char *fullPath, int line, const char *fmt, ...)
{

    const char *lastSlash = strrchr(fullPath, '/');
	const char *fileName = lastSlash + 1;
	auto now = std::chrono::system_clock::now();
	std::time_t now_t = std::chrono::system_clock::to_time_t(now);
	std::tm *tm = std::localtime(&now_t);
	int year = tm->tm_year + 1900;
	int month = tm->tm_mon + 1;
	int day = tm->tm_mday;

	timeChange(year, month, day);

	char buf[log_buf_cache] = {0};
	int len = sprintf(buf, "[%s][%d][%04d-%02d-%02d %02d:%02d:%02d]", fileName, line, year_, month_, day_, tm->tm_hour, tm->tm_min, tm->tm_sec);
	va_list aptr;
	va_start(aptr, fmt);
	vsprintf(buf + len, fmt, aptr);
	va_end(aptr);

	std::string s(buf);
	if (!gParseConfig.daemon_)
		printf("%s\n", s.c_str());
	std::unique_lock<std::mutex> lk(mutex_);
	vecLog_.push_back(std::move(s));
	lk.unlock();
	cond_.notify_one();
}

void Log::quit(const char *fullPath, int line, const char *fmt, ...)
{
	const char *lastSlash = strrchr(fullPath, '/');
	const char *fileName = lastSlash + 1;
	auto now = std::chrono::system_clock::now();
	std::time_t now_t = std::chrono::system_clock::to_time_t(now);
	std::tm *tm = std::localtime(&now_t);
	int year = tm->tm_year + 1900;
	int month = tm->tm_mon + 1;
	int day = tm->tm_mday;

	timeChange(year, month, day);
	char buf[log_buf_cache] = {0};
	int len = sprintf(buf, "[%s][%d][%04d-%02d-%02d %02d:%02d:%02d]", fileName, line, year_, month_, day_, tm->tm_hour, tm->tm_min, tm->tm_sec);
	va_list aptr;
	va_start(aptr, fmt);
	vsprintf(buf + len, fmt, aptr);
	va_end(aptr);
	std::string s(buf);
	if (!gParseConfig.daemon_)
		printf("%s\n", s.c_str());
	std::unique_lock<std::mutex> lk(mutex_);
	vecLog_.push_back(std::move(s));
	lk.unlock();
	cond_.notify_one();

	sleep(1);
	quitFlag_ = true;
	cond_.notify_one();

}