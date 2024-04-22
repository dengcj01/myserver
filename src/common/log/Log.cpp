

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
#include <stdio.h>
#include "../ParseConfig.hpp"

#define log_buf_cache 5097152

#define FORMATLOG(fileName, line)                                                                                                                                \
	timeChange();                                                                                                                                                \
	char buf[log_buf_cache] = {0};                                                                                                                               \
	struct tm tm1;                                                                                                                                               \
	time_t now = time(0);                                                                                                                                        \
	localtime_r(&now, &tm1);                                                                                                                                     \
	int len = sprintf(buf, "[%s][%s][%d][%04d-%02d-%02d %02d:%02d:%02d]", "info", fileName, line, tm1.tm_year + 1900, tm1.tm_mon + 1, tm1.tm_mday, tm1.tm_hour, tm1.tm_min, tm1.tm_sec); \
	va_list aptr;                                                                                                                                                \
	va_start(aptr, fmt);                                                                                                                                         \
	vsprintf(buf + len, fmt, aptr);                                                                                                                              \
	va_end(aptr);                                                                                                                                                \
	std::string s(buf);                                                                                                                                          \
	if (!gParseConfig.daemon_)                                                                                                                                   \
		printf("%s\n", s.c_str());                                                                                                                               \
	std::unique_lock<std::mutex> lk(mutex_);                                                                                                                     \
	vecLog_.push_back(std::move(s));                                                                                                                             \
	lk.unlock();                                                                                                                                                 \
	cond_.notify_one(); \


void Log::writeLogThreadFunc()
{
	while (true)
	{

		std::vector<std::string> tmp;
		std::unique_lock<std::mutex> lk(mutex_);

		while (vecLog_.empty())
		{
			cond_.wait(lk);
			if (quitFlag_.load(std::memory_order_relaxed) == true)
			{
				break;
			}
		}

		{
			vecLog_.swap(tmp);
			lk.unlock();

			for (auto &e : tmp)
			{
				e.append("\n");
				fputs(e.c_str(), pf_);
				fflush(pf_);
			}
		}

		if (quitFlag_.load(std::memory_order_relaxed) == true)
		{
			break;
		}
	}
}

Log::~Log()
{
	fclose(pf_);
}

std::tuple<int, int, int> Log::changeStamp(const char *line, time_t now)
{
	std::regex timeRegex("\\[(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2})\\]");
	std::smatch match;
	std::string s(line);
	if (std::regex_search(s, match, timeRegex))
	{
		std::string timeStr = match[1].str();
		std::istringstream ss(timeStr);
		struct tm tm1;
		ss >> std::get_time(&tm1, "%Y-%m-%d %H:%M:%S");
		std::tm *tm2 = std::localtime(&now);
		if(tm1.tm_year != tm2->tm_year || tm1.tm_mon != tm2->tm_mon || tm1.tm_mday != tm2->tm_mday)
		{
			return std::make_tuple(tm1.tm_year + 1900, tm1.tm_mon + 1, tm1.tm_mday);
		}
	}

	return std::make_tuple(0, 0, 0);
}

void Log::init(const char *pathName, const char *logName)
{
	pathName_ = pathName;

	if (access(pathName, 0) != 0)
	{
		mkdir(pathName_, S_IRWXU);
	}
	std::string s(pathName_);
	s.append(logName);
	logName_ = logName;

	pf_ = fopen(s.c_str(), "a+");
	if (!pf_)
	{
		printf("Log::init err\n");
		abort();
		return;
	}

	time_t now;
	time(&now);
	char line[1024];
	std::tuple<int, int, int> ret = std::make_tuple(0, 0, 0);

	while (fgets(line, sizeof(line), pf_) != NULL)
	{
		line[strcspn(line, "\n")] = 0;
		ret = changeStamp(line, now);
		break;
	}


	int year = std::get<0>(ret);
	if (year > 0)
	{
		fclose(pf_);
		char oldName[1024] = {0};
		char newName[1024] = {0};

		sprintf(newName, "%s.%04d-%02d-%02d", s.c_str(), year, std::get<1>(ret), std::get<2>(ret));
		sprintf(oldName, "%s", s.c_str());
		rename(oldName, newName);

		pf_ = fopen(s.c_str(), "a+");
	}

	struct tm *tm1 = localtime(&now);
	year_ = tm1->tm_year + 1900;
	month_ = tm1->tm_mon + 1;
	day_ = tm1->tm_mday;


	logThread_ = std::move(std::thread(&Log::writeLogThreadFunc, this));
	logThread_.detach();
}

bool Log::timeChange()
{
	if (!pf_)
	{
		return false;
	}

	time_t now = time(nullptr);
	struct tm tm1;
	localtime_r(&now, &tm1);
	if (year_ == (tm1.tm_year + 1900) &&
		month_ == tm1.tm_mon + 1 &&
		day_ == tm1.tm_mday /*&&
		hour_ == tm1.tm_hour*/
	)
	{
		return false;
	}

	fclose(pf_);
	std::string s(pathName_);
	s.append(logName_);
	char oldName[1024] = {0};
	char newName[1024] = {0};
	// sprintf(newName, "%s.%04d-%02d-%02d-%02d", s.c_str(), year_, month_, day_);
	sprintf(newName, "%s.%04d-%02d-%02d", s.c_str(), year_, month_, day_);
	sprintf(oldName, "%s", s.c_str());
	rename(oldName, newName);

	year_ = tm1.tm_year + 1900;
	month_ = tm1.tm_mon + 1;
	day_ = tm1.tm_mday;
	// hour_ = tm1.tm_hour;

	pf_ = fopen(s.c_str(), "a+");

	return true;
}

void Log::info(const char *fileName, int line, const char *fmt, ...)
{

	FORMATLOG(fileName, line);
}

void Log::quit(const char *fileName, int line, const char *fmt, ...)
{

	FORMATLOG(fileName, line);

	sleep(1);
	quitFlag_.store(true, std::memory_order_relaxed);
	cond_.notify_one();
	//logThread_.join();
}