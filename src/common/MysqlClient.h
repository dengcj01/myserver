#pragma once

#include "Singleton.h"
#include "../../libs/mysql/mysql_driver.h"
#include "../../libs/mysql/mysql_connection.h"

struct Args;
class MysqlClient : public Singleton<MysqlClient>
{
public:
    ~MysqlClient();

    void initDb(const char *ip);
    void initGlobalDb(const char *globalIp);
    sql::Connection *getMysqlCon() { return mysqlCon_; }
    sql::Connection *getCmdMysqlCon() { return cmdMysqlCon_; }
    sql::Connection *getMysqlGlobalCon() { return mysqlGlobalCon_; }
private:
    sql::mysql::MySQL_Driver *mysqlDriver_;
    sql::Connection *mysqlCon_;
    sql::Connection *cmdMysqlCon_;
    sql::mysql::MySQL_Driver *mysqlGlobalDriver_;
    sql::Connection *mysqlGlobalCon_;  

public:
};

#define gMysqlClient MysqlClient::instance()