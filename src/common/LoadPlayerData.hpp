
#pragma once
#include "../../libs/mysql/mysql_connection.h"
#include "../../libs/mysql/mysql_error.h"
#include "../../libs/mysql/cppconn/resultset.h"
#include "../../libs/mysql/cppconn/statement.h"
#include "../../libs/mysql/cppconn/prepared_statement.h"
#include "pb/ServerCommon.pb.h"
#include "log/Log.h"
#include "CommDefine.h"
#include "MysqlClient.h"

static inline uint8_t loadPlayerBaseData(uint64_t pid, PlayerBaseData &pd)
{
    sql::PreparedStatement *ps = nullptr;

    pd.set_pid(pid);

    uint8_t ret = 0;
    try
    {
        ps = gMysqlClient.getMysqlCon()->prepareStatement(queryactor);
        ps->setUInt64(1, pid);
        sql::ResultSet *rst = ps->executeQuery();
        while (rst->next())
        {
            pd.set_name(rst->getString("name"));
            pd.set_guildid(rst->getUInt64("guildid"));
            pd.set_icon(rst->getString("icon"));
            pd.set_account(rst->getString("account"));
            pd.set_pf(rst->getString("pf"));
            pd.set_createtime(rst->getInt("createtime"));
            pd.set_power(rst->getUInt64("power"));
            pd.set_level(rst->getInt("level"));
            pd.set_vip(rst->getInt("vip"));
            pd.set_exp(rst->getInt("exp"));
            pd.set_headicon(rst->getInt("headicon"));
            pd.set_title(rst->getInt("title"));
            pd.set_extra(rst->getString("extra"));
            pd.set_chargeval(rst->getInt("chargeval"));
            pd.set_logintime(rst->getInt("logintime"));
            pd.set_logouttime(rst->getInt("logouttime"));
            pd.set_fromserverid(rst->getInt("fromserverid"));
        }
        delete rst;
        ps->getMoreResults();
        delete ps;
    }
    catch (sql::SQLException &e)
    {
        logInfo(e.what());
        ret = serverdberrbase;
    }
    return ret;
}

static inline uint8_t loadPlayerBagData(uint64_t pid, ResReturnPlayerBagData &res)
{

    sql::PreparedStatement *ps = nullptr;
    uint8_t ret = 0;
    try
    {
        ps = gMysqlClient.getMysqlCon()->prepareStatement(loadplayerbagdata);
        ps->setUInt64(1, pid);

        sql::ResultSet *rst = ps->executeQuery();
        while (rst->next())
        {
            auto data = res.add_data();
            data->set_guid(rst->getUInt64("guid"));
            data->set_owner(rst->getUInt64("owner"));
            data->set_itemid(rst->getInt("itemid"));
            data->set_count(rst->getUInt64("cnt"));
            data->set_level(rst->getInt("level"));
            data->set_exp(rst->getInt("exp"));
            data->set_star(rst->getInt("star"));
            data->set_time(rst->getInt("time"));
        }
        delete rst;
        ps->getMoreResults();
        delete ps;
    }
    catch (sql::SQLException &e)
    {
        logInfo(e.what());
        ret = serverdberrbag;
    }

    return ret;
}

static inline uint8_t loadPlayerModuleData(uint64_t pid, std::map<uint8_t, std::string> &data)
{
    sql::PreparedStatement *ps = nullptr;
    uint8_t ret = 0;

    try
    {
        ps = gMysqlClient.getMysqlCon()->prepareStatement("select data, moduleid from actormodule where pid=?");
        ps->setUInt64(1, pid);

        sql::ResultSet *rst = ps->executeQuery();
        while (rst->next())
        {
            data.emplace(rst->getInt("moduleid"), rst->getString("data"));
        }
        delete rst;
        delete ps;
    }
    catch (sql::SQLException &e)
    {
        ret = serverloadmoduledataerr;
    }

    return ret;
}




static inline void __saveBaseData(const PlayerBaseData &pd, uint64_t pid)
{
    sql::PreparedStatement *ps = nullptr;
    try
    {
        ps = gMysqlClient.getMysqlCon()->prepareStatement(updateplayerbasedata);
        ps->setString(1, pd.name());
        ps->setString(2, pd.icon());
        ps->setInt64(3, pd.power());
        ps->setInt(4, pd.level());
        ps->setInt(5, pd.vip());
        ps->setInt(6, pd.exp());
        ps->setInt(7, time(0)); // 下线时间
        ps->setUInt64(8, pd.guildid());
        ps->setInt(9, pd.chargeval());
        ps->setInt(10, pd.headicon());
        ps->setInt(11, pd.title());
        ps->setInt(12, pd.skin());
        ps->setString(13, pd.extra());
        ps->setUInt64(14, pid);

        // logInfo("xxxxxxxxxxx pid:%llu, name:%s icon:%s power:%llu lv:%d vip:%d exp:%d guildid:%d chargeval:%d headicon:%d title:%d skin:%d extra:%s", pid, pd.name().data(), pd.icon().data(), pd.power(), pd.level(), pd.vip(), pd.exp(), pd.guildid(), pd.chargeval(), pd.headicon(), pd.title(), pd.skin(), pd.extra().data());

        ps->execute();
        delete ps;
    }
    catch (sql::SQLException &e)
    {
        logInfo(e.what());
    }
}

static inline void saveBaseData2Db(char *data, size_t len)
{
    ReqSavePlayerBaseData req;
    req.ParseFromArray(data, len);

    uint64_t pid = req.pid();
    auto pd = req.data();
    __saveBaseData(pd, pid);
}

static inline void __saverBagData(ReqSavePlayerBagData& req)
{
    uint64_t pid = req.pid();
    sql::PreparedStatement *ps = nullptr;
    try
    {
        ps = gMysqlClient.getMysqlCon()->prepareStatement("delete from actorbag where pid=?");
        ps->setUInt64(1, pid);
        ps->execute();
        delete ps;
    }
    catch (sql::SQLException &e)
    {
        logInfo(e.what());
    }

    try
    {
        ps = gMysqlClient.getMysqlCon()->prepareStatement("insert into actorbag(pid,guid,owner,itemId,cnt,level,exp,star,time) values(?,?,?,?,?,?,?,?,?)");
        for (int i = 0; i < req.data_size(); i++)
        {
            auto &data = req.data(i);
            ps->setUInt64(1, pid);
            ps->setUInt64(2, data.guid());
            ps->setUInt64(3, data.owner());
            ps->setInt(4, data.itemid());
            ps->setUInt64(5, data.count());
            ps->setInt(6, data.level());
            ps->setInt(7, data.exp());
            ps->setInt(8, data.star());
            ps->setInt(9, data.time());
            ps->execute();
        }
        delete ps;
    }
    catch (sql::SQLException &e)
    {
        logInfo(e.what());
    }
}

static inline void saverBagData2Db(char *data, size_t len)
{
    ReqSavePlayerBagData req;
    req.ParseFromArray(data, len);

    __saverBagData(req);
}

static inline void __saveModuleData(uint64_t pid, uint8_t moduleId, const std::string& data, uint16_t serverId)
{
    sql::PreparedStatement *ps = nullptr;
    try
    {
        ps = gMysqlClient.getMysqlCon()->prepareStatement("replace into actormodule(pid,moduleid,data,serverid)values(?,?,?,?)");
        ps->setUInt64(1, pid);
        ps->setInt(2, moduleId);
        ps->setString(3, data);
        ps->setInt(4, serverId);
        ps->execute();
        delete ps;
    }
    catch (sql::SQLException &e)
    {
        logInfo(e.what());
    }
}

static inline void saveModuleData2Db(char *data, size_t len)
{
    ReqSavePlayerModuleData req;
    req.ParseFromArray(data, len);
    uint64_t pid = req.pid();
    uint16_t serverId = req.serverid();
    uint8_t moduleId = req.moduleid();

    __saveModuleData(pid, moduleId, req.data(), serverId);
}

static inline uint8_t updatePlayerLoginTime(uint64_t pid)
{
    uint8_t ret = 0;
    try
    {
        sql::PreparedStatement *ps = gMysqlClient.getMysqlCon()->prepareStatement(updatelogintime);
        ps->setUInt64(1, pid);
        ps->setInt(2, time(0));
        ps->execute();
        delete ps;
    }
    catch (sql::SQLException &e)
    {
        logInfo(e.what());
        ret = serverupdatetimeerr;
    }

    return ret;
}