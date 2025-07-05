#pragma once
#include <iostream>
#include <fstream>
#include <string>
#include <unordered_map>
#include <regex>
#include <vector>
#include <codecvt>
#include "Singleton.h"
#include "Json.hpp"
#include "log/Log.h"
#include "MysqlClient.h"
#include "../../libs/mysql/mysql_connection.h"
#include "../../libs/mysql/mysql_error.h"
#include "../../libs/mysql/cppconn/resultset.h"
#include "../../libs/mysql/cppconn/statement.h"
#include "../../libs/mysql/cppconn/prepared_statement.h"


const uint16_t defaultMasterPort = 1000;

class ParseConfig : public Singleton<ParseConfig>
{
public:
    ~ParseConfig()
    {
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

    bool isDaemon() {return daemon_;}
    void parseConfig(const std::string &str, const char *cfg = nullptr)
    {

        std::string s = str;
        if (!cfg)
        {
            s.append("config.json");
        }
        else
        {
            s.append(cfg);
        }

        std::ifstream ifs(s.data());
        nlohmann::json js;
        ifs >> js;

        serverId_ = js.at("server_id");
        serverPort_ = js.at("server_port");
        dbPort_ = js.at("db_port");
        daemon_ = js.at("daemon") == 1 ? true : false;
        dbName_ = js.at("db_name");
        name_ = js.at("server_name");
        gamePort_ = js.at("game_port");
        sqlAccount_ = js.at("sql_account");
        sqlPasswd_ = js.at("sql_passwd");
        dbIp_ = js.at("db_ip");
        gmlv_ = js.at("gm_lv");


        glbaldataDbIp_ = js.at("wx_glbaldata_ip");

    }

    bool isMasterServer()
    {
        return name_ == "master";
    }

    bool isGameServer()
    {
        return name_ == "game";
    }
    bool isDbServer()
    {
        return name_ == "db";
    }
    bool isGateServer()
    {
        return name_ == "gate";
    }

    uint16_t getMasterServerId()
    {
        return masterServerId_;
    }

    bool isDevelopServer()
    {
        return gmlv_ == 1;
    }

    bool parseCrossConfig()
    {
        if (!isMasterServer() && !isGameServer())
        {
            return true;
        }

        sql::PreparedStatement *ps = nullptr;
        sql::ResultSet *rst = nullptr;
        try
        {
            ps = gMysqlClient.getMysqlGlobalCon()->prepareStatement("select * from lianfuconfig");
            if(!ps)
            {
                logInfo("parseCrossConfig ps error");
                return false;
            }

            rst = ps->executeQuery();
            if(!rst)
            {
                logInfo("parseCrossConfig rst error");
                return false;
            }

            bool ok = false;

            while (rst->next())
            {
                std::string serverList = rst->getString("serverlist");
                std::vector<uint16_t> servers = splitString<uint16_t>(serverList);
                uint16_t crossId = rst->getInt("crossid");

                uint16_t idx = rst->getInt("id");
                std::string ip = rst->getString("hostname");

                if (serverId_ == crossId)
                {
                    masterIp_ = ip;
                    masterServerId_ = crossId;
                    masterPort_ = defaultMasterPort + crossId;
                }

                if (isGameServer() && ok == false)
                {
                    auto it = std::find(servers.begin(), servers.end(), serverId_);
                    if (it != servers.end())
                    {
                        masterIp_ = ip;
                        masterServerId_ = crossId;
                        masterPort_ = defaultMasterPort + crossId;
                        ok = true;
                    }
                }

                master_.emplace(crossId, idx);
            }

            delete rst;
            delete ps;

            if (!ok && isGameServer())
            {
                logInfo("------------------解析跨服配置错误,服务器= %d 未配置进跨服---------------", serverId_);
            }
        }
        catch (sql::SQLException &e)
        {
            logInfo(e.what());
        }

        return true;
    }

    uint16_t getMasterIdx(uint16_t masterId)
    {
        auto it = master_.find(masterId);
        if (it == master_.end())
        {
            return 0;
        }
        return it->second;
    }

    uint16_t getServerId()
    {
        return serverId_;
    }

    uint16_t serverId_;               // 服务器id
    std::string name_ = "master";     // 服务器名字
    uint16_t serverPort_;             // 服务器端口
    uint16_t dbPort_;                 // db服务器端口
    std::string dbIp_ = "127.0.0.1";  // db服务器ip
    uint16_t masterPort_;             // 主连服端口
    std::string masterIp_;            // 主连服ip
    uint16_t masterServerId_;         // 主连服服务器id
    bool daemon_;                     // 守护进程标志
    std::string dbName_;              // 数据库名字
    std::string glbaldataDbIp_;       // 跨服数据库ip
    uint16_t gamePort_;               // game进程端口
    std::string sqlAccount_;
    std::string sqlPasswd_;
    uint8_t gmlv_ = 0;


    std::unordered_map<uint16_t, uint16_t> master_;
};

#define gParseConfig ParseConfig::instance()