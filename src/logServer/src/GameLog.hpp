

#pragma once
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <string>
#include <iomanip>
#include <sys/file.h>
#include <map>

#include "../../common/Singleton.h"
#include "../../common/pb/ServerCommon.pb.h"
#include "../../common/Json.hpp"
#include "../../common/log/Log.h"

class GameLog : public Singleton<GameLog>
{
public:
    ~GameLog() {}

public:
    std::string formatTime(time_t timestamp, uint8_t opt)
    {
        std::tm *timeinfo = std::localtime(&timestamp);

        std::ostringstream oss;
        if (opt == 1)
        {
            oss << std::put_time(timeinfo, "%Y-%m-%d");
            return oss.str();
        }

        oss << std::put_time(timeinfo, "%Y-%m-%d %H:%M:%S");
        return oss.str();
    }

    void init(std::string pathName)
    {

        pathName.append("tlog/");
        auto name = pathName.c_str();
        if (access(name, 0) != 0)
        {
            mkdir(name, S_IRWXU);
        }
        path_ = pathName;

        uint32_t curTime = time(0);
        std::string s = path_;

        s.append("log_mail_ex_");
        s.append(formatTime(curTime, 1));

        mailPf_ = fopen(s.c_str(), "a+");
        if (!mailPf_)
        {
            printf("Log::init mail err\n");
            abort();
            return;
        }

        s = path_;
        s.append("log_reward_ex_");
        s.append(formatTime(curTime, 1));

        rdPf_ = fopen(s.c_str(), "a+");
        if (!rdPf_)
        {
            printf("Log::init rd err\n");
            abort();
            return;
        }

        time_t now = curTime;
        time(&now);
        struct tm *tm1 = localtime(&now);
        year_ = tm1->tm_year + 1900;
        month_ = tm1->tm_mon + 1;
        day_ = tm1->tm_mday;
    }

    void write(const WriteMailData &wd, uint32_t curTime)
    {
        std::map<std::string, std::string> m;
        m.emplace("pid", std::to_string(wd.pid()));
        m.emplace("account", wd.account());
        m.emplace("pf", wd.pf());
        m.emplace("name", wd.name());
        m.emplace("updatetime", formatTime(curTime, 2));
        m.emplace("serverid", std::to_string(wd.serverid()));

        auto li = wd.data();
        for (auto &e : li)
        {
            
            m.emplace("mailid", std::to_string(e.mailid()));
            m.emplace("desc", e.desc());
            m.emplace("reward", e.reward());
            m.emplace("extra", e.extra());
            m.emplace("title", e.title());
            m.emplace("content", e.content());
            m.emplace("expiretime", std::to_string(e.expiretime()));

            writeFile(m, curTime, 2);

            m.erase("mailid");
            m.erase("desc");
            m.erase("reward");
            m.erase("extra");
            m.erase("title");
            m.erase("content");
            m.erase("expiretime");
        }
    }

    void write(const WriteLogData &wd, uint32_t curTime)
    {
        std::map<std::string, std::string> m;

        m.emplace("pid", std::to_string(wd.pid()));
        m.emplace("account", wd.account());
        m.emplace("pf", wd.pf());
        m.emplace("desc", wd.desc());
        m.emplace("serverid", std::to_string(wd.serverid()));
        m.emplace("updatetime", formatTime(curTime, 2));
        m.emplace("extra", wd.extra());
        m.emplace("name", wd.name());

        auto li = wd.data();
        for (auto &e : li)
        {
            m.emplace("itemid", std::to_string(e.id()));
            m.emplace("cnt", std::to_string(e.cnt()));
            m.emplace("oldcnt", std::to_string(e.oldcnt()));

            writeFile(m, curTime, 1);

            m.erase("itemid");
            m.erase("cnt");
            m.erase("oldcnt");
        }
    }

    bool timeChange(uint32_t curTime)
    {

        time_t now = curTime;
        struct tm tm1;
        localtime_r(&now, &tm1);
        if (year_ == (tm1.tm_year + 1900) &&
            month_ == tm1.tm_mon + 1 &&
            day_ == tm1.tm_mday)
        {
            return false;
        }
        year_ = tm1.tm_year + 1900;
        month_ = tm1.tm_mon + 1;
        day_ = tm1.tm_mday;

        return true;
    }

private:
    void writeFile(std::map<std::string, std::string> &m, uint32_t curTime, uint8_t opt)
    {
        if (timeChange(curTime))
        {
            fclose(rdPf_);
            fclose(mailPf_);
            std::string stime = formatTime(curTime, 1);

            std::string s = path_;
            s.append("log_mail_ex_");
            s.append(stime);
            mailPf_ = fopen(s.c_str(), "a+");

            s = path_;
            s.append("log_reward_ex_");
            s.append(stime);
            rdPf_ = fopen(s.c_str(), "a+");
        }

        FILE *pf = 0;
        if (opt == 1)
        {
            pf = rdPf_;
        }
        else if (opt == 2)
        {
            pf = mailPf_;
        }
        else
        {
            logInfo("-----------------------writeFile err %d", opt);
            return;
        }

        if (!pf)
        {
            logInfo("-----------------------writeFile err1 %d", opt);
            return;
        }

        nlohmann::json tmp = m;
        std::string val = tmp.dump();
        val.append("\n");

        int fd = fileno(pf);
        flock(fd, LOCK_EX); // 获取文件锁
        fputs(val.c_str(), pf);
        fflush(pf);
        flock(fd, LOCK_UN);
    }

private:
    std::string path_;
    FILE *mailPf_;
    FILE *rdPf_;
    int year_;
    int month_;
    int day_;
};

#define gGameLog GameLog::instance()