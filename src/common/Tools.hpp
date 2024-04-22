#pragma once
#include <string>
#include <unistd.h>
#include <stdio.h>
#include <regex>
#include <vector>
#include <codecvt>
#include <chrono>
#include <malloc.h>
#include <random>
#include <iostream>
#include <sys/time.h>

#include "Singleton.h"
#include "ParseConfig.hpp"

class Tools : public Singleton<Tools>
{
public:
    uint64_t millisTime = 0;

    // 获取path的绝对路径
    std::string getAbsolutePath(const std::string &path)
    {
        char resolvedPath[100];
        if (realpath(path.data(), resolvedPath) == NULL)
        {
            return "";
        }
        return std::string(resolvedPath);
    }

    // 获取当前路径的父目录
    std::string getParentPath(const std::string &str)
    {
        if (str.empty())
        {
            return "";
        }

        size_t pos = str.rfind("/");
        if (pos == std::string::npos)
        {
            return "";
        }

        return str.substr(0, pos + 1);
    }

    // 获取当前路径的父父目录
    const char *getParen2tPath(const std::string &str)
    {

        std::string s = str;
        s.pop_back();
        size_t pos = s.rfind("/");
        return s.substr(0, pos + 1).c_str();
    }

    uint64_t getMillisTime(uint32_t timestamp = 0)
    {
        if (timestamp == 0)
        {
            return static_cast<uint64_t>(std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count());
        }
        auto timePoint = std::chrono::system_clock::from_time_t(timestamp);
        return std::chrono::time_point_cast<std::chrono::milliseconds>(timePoint).time_since_epoch().count();
    }

    double getClock()
    {
        struct timeval start;
        gettimeofday(&start, NULL);
        double totaltime = start.tv_sec + start.tv_usec / 1000000.0;
        return totaltime;
    }

    template <typename T>
    std::vector<T> splitString(const std::string &str)
    {
        std::vector<T> result;
        std::regex pattern("\\d+");
        std::smatch matches;
        for (auto it = std::sregex_iterator(str.begin(), str.end(), pattern); it != std::sregex_iterator(); ++it)
        {
            result.emplace_back(std::stoi(it->str()));
        }

        return result;
    }

    std::wstring changeStr(const std::string &str)
    {
        std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
        return converter.from_bytes(str);
    }

    std::wstring changeStr(const char *str)
    {
        std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
        return converter.from_bytes(str);
    }

    bool isChineseCharacter(wchar_t c)
    {
        return (c >= 0x4e00 && c <= 0x9fa5);
    }

    void mallocTrim()
    {
        malloc_trim(0);
    }

    uint64_t createUniqueId()
    {
        uint64_t id = gParseConfig.serverId_;
        id <<= 48;

        uint64_t curTime = getMillisTime();
        while (curTime <= millisTime)
        {
            curTime = getMillisTime();
        }

        millisTime = curTime;
        id |= millisTime;

        return id;
    }

    uint16_t reverServerId(uint64_t id)
    {
        return ((id & 0xFFFF000000000000) >> 48) & 0xFFFF;
    }

    bool isValidStr(const char *str)
    {
        std::wstring text = changeStr(str);
        if (text.length() == 0)
        {
            return false;
        }

        for (wchar_t &c : text)
        {
            if (!isChineseCharacter(c) && !std::iswalpha(c))
            {
                return false;
            }
        }

        return true;
    }

    uint32_t get0Time(uint32_t timeStamp)
    {
        auto tp = std::chrono::time_point<std::chrono::system_clock>(std::chrono::seconds(timeStamp));
        auto sysTime = std::chrono::system_clock::to_time_t(tp);
        auto localTime = localtime(&sysTime);
        localTime->tm_hour = 0;
        localTime->tm_min = 0;
        localTime->tm_sec = 0;
        auto zeroTimePoint = std::chrono::system_clock::from_time_t(mktime(localTime));
        auto zeroTimeStamp = std::chrono::duration_cast<std::chrono::seconds>(zeroTimePoint.time_since_epoch()).count();
        return zeroTimeStamp;
    }

    std::string getStringTime(long nowTime)
    {
        struct tm timeinfo;
        localtime_r(&nowTime, &timeinfo);
        char datetime[15];
        strftime(datetime, sizeof(datetime), "%Y%m%d%H%M%S", &timeinfo);
        return std::string(datetime);
    }

    uint32_t random(uint32_t s, uint32_t e, uint32_t seed = 0)
    {
        if(seed > 0)
        {
            std::mt19937 gen(seed);
            std::uniform_int_distribution<uint32_t> dis(s, e);
            return dis(gen);
        }
        else
        {
            std::random_device rd;
            std::mt19937 gen(rd());
            std::uniform_int_distribution<uint32_t> dis(s, e);
            return dis(gen);
        }
    }

    template <typename T>
    void printMap(const T &t)
    {
        std::cout << "开始打印map数据" << std::endl;
        for (auto &e : t)
        {
            std::cout << "key:"<< e.first << " " << "val:"<<e.second << std::endl;
        }
    }

    template <typename T>
    void printList(const T &t)
    {
        std::cout << "开始打印list数据" << std::endl;
        for (auto &e : t)
        {
            std::cout << e << " ";
        }
        std::cout<<std::endl;
    }
};

#define gTools Tools::instance()
