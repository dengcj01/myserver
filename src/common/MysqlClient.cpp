
#include "MysqlClient.h"

#include "../../libs/mysql/mysql_error.h"
#include "../../libs/mysql/cppconn/resultset.h"
#include "../../libs/mysql/cppconn/statement.h"
#include "../../libs/mysql/cppconn/prepared_statement.h"
#include "../../libs/jemalloc/jemalloc.h"
#include "ParseConfig.hpp"
#include "log/Log.h"
#include "net/Data.h"
#include "Timer.hpp"

MysqlClient::~MysqlClient()
{
    if (mysqlCon_)
    {
        delete mysqlCon_;
    }
}

void MysqlClient::initGlobalDb(const char *globalIp)
{
    if (gParseConfig.isGameServer() || gParseConfig.isMasterServer())
    {
        mysqlGlobalDriver_ = sql::mysql::get_driver_instance();
        if (!mysqlGlobalDriver_)
        {
            logQuit("create mysql global driver err");
            _exit(0);
        }

        try
        {

            mysqlGlobalCon_ = mysqlGlobalDriver_->connect(globalIp, "root", "0987abc123");
            mysqlGlobalCon_->setSchema("wx_globaldata");
            logInfo("------------------------connect wx_globaldata success------------------------");
        }
        catch (sql::SQLException &e)
        {
            logQuit(e.what());
            _exit(0);
        }
    }
}

void MysqlClient::initDb(const char *ip)
{
    if (!gParseConfig.isLogServer())
    {
        mysqlDriver_ = sql::mysql::get_driver_instance();
        if (!mysqlDriver_)
        {
            logQuit("create mysql driver err");
            _exit(0);
        }

        try
        {

            mysqlCon_ = mysqlDriver_->connect(ip, "root", "0987abc123");
            mysqlCon_->setSchema(gParseConfig.dbName_.data());
            logInfo("------------------------connect mysql success------------------------");
        }
        catch (sql::SQLException &e)
        {
            logQuit(e.what());
            _exit(0);
        }
    }


}
