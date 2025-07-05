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
#include <execinfo.h>
#include <sys/time.h>

#include "Singleton.h"
#include "ParseConfig.hpp"



class Tools : public Singleton<Tools>
{
public:
    uint64_t millisTime_ = 0;
    uint64_t sequence_ = 0;  // 序列号
    uint64_t lastTimestamp_ = 0;    // 最后时间戳
    uint64_t epoch_ = 1735660800000; // 2025-01-01 00:00:00
    
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

    int64_t getMillisTime(uint32_t timestamp = 0)
    {
        if (timestamp == 0)
        {
            return static_cast<int64_t>(std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count());
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

    uint64_t wait(uint64_t timestamp)
    {
        while (timestamp == lastTimestamp_)
        {
            std::this_thread::sleep_for(std::chrono::microseconds(100));
            timestamp = getMillisTime() - epoch_;
        }
        return timestamp;
    }

    uint64_t createUniqueId()
    {
        uint64_t id = gParseConfig.serverId_;
        uint64_t curTime = getMillisTime();
        uint64_t timestamp = curTime - epoch_;

        // 处理时间回退情况
        if (timestamp < lastTimestamp_)
        {
            // 时间回退时重置序列号
            sequence_ = 0;
        }
        else if (timestamp == lastTimestamp_)
        {
            // 同一毫秒内递增序列号
            sequence_ = (sequence_ + 1) & 0x3F;  // 6位序列号 (0-64)
            // 序列号耗尽时等待到下一毫秒
            if (sequence_ == 0)
            {
                timestamp = wait(timestamp);
            }
        }
        else
        {
            sequence_ = 0;
        }


        lastTimestamp_ = timestamp;

        id = (id << 47) | (timestamp << 6) | sequence_;

        return id;
    }

    std::string toLowerCase(const std::string& str) 
    {
        std::string result = str;
        std::transform(result.begin(), result.end(), result.begin(),
            [](unsigned char c) { return std::tolower(c); });
        return result;
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

    // 安装指定格式分割字符串
    std::vector<std::string> splitBydelimiter(const std::string& str, const std::string& delimiter)
    {
        std::vector<std::string> result;

        if (delimiter.empty() || str.empty())
        {
            return result;
        }

        if (str.find(delimiter) == std::string::npos) 
        {
            result.emplace_back(str);
            return result;
        }

        std::string::size_type start = 0;
        std::string::size_type end = 0;
        try
        {
            while ((end = str.find(delimiter, start)) != std::string::npos) 
            {
                result.push_back(str.substr(start, end - start));
                start = end + 1;
            }
        }
        catch(const std::exception& e)
        {
            logInfo(e.what());
        }


        return result;
    }

    // 是否只含有数字或者字母
    bool isValidString(const std::string& str) 
    {
        for (char c : str) 
        {
            if (!std::isalnum(c)) 
            {
                return false;
            }
        }
        return true;
    }

    // 是否是整分钟
    bool isWholeMinute(std::time_t timestamp) 
    {
        std::tm* timeinfo = std::localtime(&timestamp);
        return (timeinfo->tm_sec == 0);
    }


    // 移除所有空格
    std::string removeSpaces(const std::string& str) 
    {
        std::string result;
        for (char c : str) 
        {
            if (!std::isspace(c)) 
            {
                result += c;
            }
        }
        return result;
    }


    bool startAndEndhaveSpace(const std::string& str) 
    {
		if(std::isspace(str[0]) || std::isspace(str[str.size()-1]))
		{
			return true;
		}
        return false;
    }

    // 去除字符串前后的空格
    std::string trim(const std::string& str) 
    {
        if (str.empty()) return str;

        // 找到第一个非空格字符的位置
        auto first_non_space = std::find_if_not(str.begin(), str.end(), [](unsigned char c) {
            return std::isspace(c);
            });

        // 找到最后一个非空格字符的位置
        auto last_non_space = std::find_if_not(str.rbegin(), str.rend(), [](unsigned char c) {
            return std::isspace(c);
            }).base();

        // 如果第一非空字符的位置在最后非空字符的位置之前，返回子字符串
        if (first_non_space < last_non_space) {
            // 只保留第一个字符和最后一个字符之间的内容
            return std::string(first_non_space, last_non_space);
        }
        else {
            return std::string(); // 返回空字符串
        }
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

    time_t timestampDatetime(const std::string &datetime) 
    {
        std::tm tm = {};
        std::istringstream ss(datetime);
        
        ss >> std::get_time(&tm, "%Y-%m-%d %H:%M:%S");
        if (ss.fail()) 
        {
            return 0;
        }
        
        // 将解析后的时间转换为 time_t
        return std::mktime(&tm);
    }

    uint32_t getNowTime()
    {
        std::chrono::system_clock::time_point times = std::chrono::system_clock::now();
        std::time_t nowTime = std::chrono::system_clock::to_time_t(times);
        std::tm ltime = *std::localtime(&nowTime);
        auto timeZone = std::chrono::system_clock::from_time_t(std::mktime(&ltime));
        return std::chrono::system_clock::to_time_t(timeZone);
    }

    std::string getStringTime(long nowTime)
    {
        std::tm* timeInfo = std::localtime(&nowTime);
        char datetime[20];
        strftime(datetime, sizeof(datetime), "%Y%m%d%H%M%S", timeInfo);
        return std::string(datetime);
    }

    std::string timestampToString(long timestamp) 
    {
        // 将时间戳转换为时间结构
        std::tm* timeInfo = std::localtime(&timestamp);

        // 使用字符串流格式化时间
        std::ostringstream oss;
        oss << std::put_time(timeInfo, "%Y/%m/%d %H:%M:%S");

        return oss.str();
    }


    uint32_t randoms(uint32_t s, uint32_t e, uint32_t seed = 0)
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

    void mySleep(int32_t sec)
    {
        sleep(sec);
    }

    std::string getNowYMD() 
    {
        std::chrono::system_clock::time_point now = std::chrono::system_clock::now();
        time_t nowTime = std::chrono::system_clock::to_time_t(now);
        struct tm* parts = std::localtime(&nowTime);

        char buffer[20];
        std::strftime(buffer, 20, "%Y%m%d", parts);
        return std::string(buffer);
    }

    long getNowTimeByDate(int year, int month, int day, int hour = 0, int minute = 0, int second = 0) 
    {
        std::tm timeInfo = {};
        timeInfo.tm_year = year - 1900;  
        timeInfo.tm_mon = month - 1; 
        timeInfo.tm_mday = day;
        timeInfo.tm_hour = hour;
        timeInfo.tm_min = minute;
        timeInfo.tm_sec = second;

        long timestamp = std::mktime(&timeInfo);
        return timestamp;
    }

    bool isSameDay(time_t timestamp1, time_t timestamp2) 
    {

        std::tm *tm1 = std::localtime(&timestamp1);
        int year1 = tm1->tm_year + 1900;
        int month1 = tm1->tm_mon + 1;
        int day1= tm1->tm_mday;

        std::tm *tm2 = std::localtime(&timestamp2);
        int year2 = tm2->tm_year + 1900;
        int month2 = tm2->tm_mon + 1;
        int day2 = tm2->tm_mday;

        return year1 == year2 && month1 == month2 && day1==day2;
    }

    // 计算2个时间戳相隔几天
    int getDiffDay(std::time_t timestamp1, std::time_t timestamp2) 
    {
        double secondsDiff = std::difftime(timestamp2, timestamp1);
        
        // 将秒数差转换为天数
        int daysDiff = static_cast<int>(std::round(secondsDiff / (60 * 60 * 24)));
        
        return daysDiff;
    }

    // 获取今天是周几
    int getDayOfWeek(time_t timestamp) 
    {
        struct tm* timeinfo;
        timeinfo = localtime(&timestamp);

        int weekday = timeinfo->tm_wday;

        if (weekday == 0) {
            return 7; // 将周日的表示由0改为7
        } else {
            return weekday;
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

    const char* printStackTrace() 
    {
        void *array[30];
        size_t size;
        
        size = backtrace(array, 30);

        std::ostringstream stackStream;
        stackStream << "Stack trace (most recent call last):\n";

        char **symbols = backtrace_symbols(array, size);
        if (symbols != nullptr) {
            for (size_t i = 0; i < size; ++i) 
            {
                stackStream << symbols[i] << "\n";
            }
            free(symbols); // 释放由 backtrace_symbols 分配的内存
        }

        return stackStream.str().data(); // 返回堆栈信息字符串
    }
};

#define gTools Tools::instance()
