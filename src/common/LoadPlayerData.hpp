
#pragma once
#include <memory>
#include "../../libs/mysql/mysql_connection.h"
#include "../../libs/mysql/mysql_error.h"
#include "../../libs/mysql/cppconn/resultset.h"
#include "../../libs/mysql/cppconn/statement.h"
#include "../../libs/mysql/cppconn/prepared_statement.h"
#include "log/Log.h"
#include "CommDefine.h"
#include "MysqlClient.h"
#include "Tools.hpp"
#include "Json.hpp"
#include "pb/Server.pb.h"
#include "pb/Player.pb.h"

static inline nlohmann::json packPlayerBaseData2Json(const PlayerBaseData& rp, uint32_t logoutTime = 0) 
{
    nlohmann::json j;
    j["pid"] = rp.pid();
    j["level"] = rp.level();
    j["name"] = rp.name();
    j["account"] = rp.account();
    j["serverId"] = rp.serverid();
    j["vip"] = rp.vip();
    j["icon"] = rp.icon();
    j["skin"] = rp.skin();
    j["title"] = rp.title();
    j["headIcon"] = rp.headicon();
    j["power"] = rp.power();
    j["guildId"] = rp.guildid();
    j["sex"] = rp.sex();
    j["logoutTime"] = logoutTime;

    return j;
}

static inline nlohmann::json parseBaseDataFromDb(std::unique_ptr<sql::ResultSet>& rst, PlayerBaseData &pd, bool isOne)
{
	nlohmann::json jsonData = nlohmann::json::array(); 
    while (rst->next())
    {
        pd.set_name(rst->getString("name"));
        pd.set_guildid(rst->getUInt64("guildid"));
        pd.set_icon(rst->getString("icon"));
        pd.set_account(rst->getString("account"));
        pd.set_pf(rst->getString("pf"));
        pd.set_createtime(gTools.timestampDatetime(rst->getString("createtime")));

        pd.set_power(rst->getUInt64("power"));
        pd.set_level(rst->getInt("level"));
        pd.set_vip(rst->getInt("vip"));
        pd.set_exp(rst->getInt("exp"));
        pd.set_headicon(rst->getInt("headicon"));
        pd.set_title(rst->getInt("title"));
        pd.set_extra(rst->getString("extra"));
        pd.set_chargeval(rst->getInt("chargeval"));
        pd.set_logintime(gTools.timestampDatetime(rst->getString("logintime")));

        pd.set_logouttime(gTools.timestampDatetime(rst->getString("logouttime")));
        pd.set_fromserverid(rst->getInt("fromserverid"));
        pd.set_firstlogintime(gTools.timestampDatetime(rst->getString("firstlogintime")));
        pd.set_bantime(gTools.timestampDatetime(rst->getString("bantime")));
        pd.set_banreason(rst->getString("banreason"));
        pd.set_serverid(rst->getUInt("serverid"));
        pd.set_gmlv(rst->getUInt("gmlv"));      
        pd.set_sex(rst->getInt("sex"));        
        pd.set_pid(rst->getUInt64("pid"));

        if(isOne)
        {
            break;
        }
        else
        {
            const nlohmann::json& j = packPlayerBaseData2Json(pd);
            jsonData.emplace_back(j);
        }    
    }
    return jsonData;
}
static inline uint8_t loadPlayerBaseData(uint64_t pid, PlayerBaseData &pd)
{
    auto con = gMysqlClient.getMysqlCon();
    if(!con)
    {
        logInfo("loadPlayerBaseData ps err %lu", pid);
        return ServerErrorCode::CreateSqlError;
    }
    else
    {
        try
        {
            std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("select * from actors where pid=?"));
            if (!ps)
            {
                logInfo("loadPlayerBaseData ps err %lu", pid);
                return ServerErrorCode::CreateSqlError;
            }

            ps->setUInt64(1, pid);
            
            std::unique_ptr<sql::ResultSet> rst = std::unique_ptr<sql::ResultSet>(ps->executeQuery());
            if (!rst)
            {
                logInfo("loadPlayerBaseData rst err %lu", pid);
                return ServerErrorCode::CreateSqlError;
            }

            parseBaseDataFromDb(rst, pd, true);
        }
        catch (sql::SQLException &e)
        {
            logInfo(e.what());
            return ServerErrorCode::DbErrorBase;
        }
    }

    return 0;
}


static inline uint8_t loadPlayerModuleData(uint64_t pid, std::map<uint8_t, std::string> &data)
{
    auto con = gMysqlClient.getMysqlCon();
    if(!con)
    {
        logInfo("loadPlayerBaseData ps err %lu", pid);
        return ServerErrorCode::CreateSqlError;
    }
    else
    {
        try
        {
            std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("select data, moduleid from actormodule where pid=?"));
            if (!ps)
            {
                logInfo("loadPlayerModuleData ps err %lu", pid);
                return ServerErrorCode::CreateSqlError;
            }
            else
            {
                ps->setUInt64(1, pid);

                std::unique_ptr<sql::ResultSet> rst = std::unique_ptr<sql::ResultSet>(ps->executeQuery());

                if (!rst)
                {
                    logInfo("loadPlayerModuleData rst err %lu", pid);
                    return ServerErrorCode::CreateSqlError;
                }

                while (rst->next())
                {
                    data.emplace(rst->getInt("moduleid"), rst->getString("data"));
                }
            }
        }
        catch (sql::SQLException &e)
        {
            logInfo(e.what());
            return ServerErrorCode::LoadModuleDataError;
        }
    }


    return 0;
}

static inline uint8_t loadPlayerOneModuleData(uint64_t pid, uint8_t moduleId, std::string& data)
{
    uint8_t code = 1;
    auto con = gMysqlClient.getMysqlCon();
    if(!con)
    {
        logInfo("loadPlayerOneModuleData ps err %lu", pid);
    }
    else
    {
        try
        {
            con->setAutoCommit(false);
            std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("select data, moduleid from actormodule where pid=? for update"));
            if (!ps)
            {
                con->setAutoCommit(true);
                logInfo("loadPlayerOneModuleData ps err %lu", pid);
            }
            else
            {
                ps->setUInt64(1, pid);
                std::unique_ptr<sql::ResultSet> rst = std::unique_ptr<sql::ResultSet>(ps->executeQuery());
    
                if (!rst)
                {
                    con->setAutoCommit(true);
                    logInfo("loadPlayerOneModuleData rst err %lu", pid);
                }
    
                while (rst->next())
                {
                    data = rst->getString("data");
                    break;
                }
                con->setAutoCommit(true);
                
                code = 0;
                if(data.size() == 0)
                {
                    data = "{}";
                }
            }
        }
        catch (sql::SQLException &e)
        {
            con->rollback();
            con->setAutoCommit(true);
            logInfo(e.what());
        }
    }

    return code;    
}

static inline void __saveModuleData(uint64_t pid, uint8_t moduleId, const std::string &data, uint16_t serverId)
{
    auto con = gMysqlClient.getMysqlCon();
    if(!con)
    {
        logInfo("__saveModuleData ps err %lu", pid);
        return;
    }

    try
    {
        con->setAutoCommit(false);
        std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("replace into actormodule(pid,moduleid,data,serverid)values(?,?,?,?)"));
        if (!ps)
        {
            con->setAutoCommit(true);
            logInfo("__saveModuleData ps err %lu", pid);
        }
        else
        {
            ps->setUInt64(1, pid);
            ps->setUInt(2, moduleId);
            ps->setString(3, data);
            ps->setInt(4, serverId);

            //logInfo("__saveModuleData111 %llu %d", pid, moduleId);
            ps->execute();
            //logInfo("__saveModuleData222 %llu %d", pid, moduleId);
            con->setAutoCommit(true);
        }

    }
    catch (sql::SQLException &e)
    {
        con->rollback();
        con->setAutoCommit(true);
        logInfo("__saveModuleData %lu %s", pid, e.what());
    }


}


static inline void __saveBaseData(const PlayerBaseData &pd, uint64_t pid, uint8_t opt = 0)
{
    auto con = gMysqlClient.getMysqlCon();
    if(!con)
    {
        logInfo("__saveBaseData ps err %lu", pid);
        return;
    }

   // logInfo("__saveBaseData__saveBaseData__saveBaseData %d", opt);

    try
    {
        if(opt == 1)
        {
            std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("update actors set banTime=from_unixtime(?),banreason=? where pid=?"));
            if (!ps)
            {
                logInfo("__saveBaseData ps err %lu", pid);
            }
            else
            {
                ps->setUInt(1, pd.bantime());
                ps->setString(2, pd.banreason());   
                ps->setUInt64(3, pid); 
                
                logInfo("__saveBaseData__saveBaseData111 %llu %u %s", pid, pd.bantime(), pd.banreason().data());
                ps->execute();
                logInfo("__saveBaseData__saveBaseData111 %llu %d", pid, opt);
            }
        }
        else
        {
            std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("update actors set name =?,icon=?,power=?,level=?,vip=?,exp=?,logouttime=from_unixtime(?),guildid=?,chargeval=?,headicon=?,title=?,skin=?,extra=?,logintime=from_unixtime(?),bantime=from_unixtime(?),banreason=?,serverid=?,fromserverid=?,gmlv=? where pid=?"));
            if (!ps)
            {
                logInfo("__saveBaseData ps err %lu", pid);
            }
            else
            {
                ps->setString(1, pd.name());
                ps->setString(2, pd.icon());
                ps->setInt64(3, pd.power());
                ps->setUInt(4, pd.level());
                ps->setUInt(5, pd.vip());
                ps->setUInt(6, pd.exp());
                ps->setUInt(7, gTools.getNowTime()); // 下线时间
                ps->setUInt64(8, pd.guildid());
                ps->setUInt(9, pd.chargeval());
                ps->setUInt(10, pd.headicon());
                ps->setUInt(11, pd.title());
                ps->setUInt(12, pd.skin());
                ps->setString(13, pd.extra());
                ps->setUInt(14, pd.logintime());
                if(pd.bantime() == 0)
                {
                    ps->setNull(15, sql::DataType::SQLNULL);
                }
                else
                {
                    ps->setUInt(15, pd.bantime());
                }
               
                ps->setString(16, pd.banreason());
                ps->setUInt(17, pd.serverid());
                ps->setUInt(18, pd.fromserverid()); 
                ps->setUInt(19, pd.gmlv());               
                ps->setUInt64(20, pid);

                //logInfo("xxxxxxxxxxx pid:%llu, name:%s icon:%s power:%llu lv:%d vip:%d exp:%d guildid:%llu chargeval:%d headicon:%d title:%d skin:%d extra:%s logintime:%u bantime:%u banreason:%s serverid:%d fromserverid:%d gmlv:%d", pid, pd.name().data(), pd.icon().data(), pd.power(), pd.level(), pd.vip(), pd.exp(), pd.guildid(), pd.chargeval(), pd.headicon(), pd.title(), pd.skin(), pd.extra().data(),pd.logintime(),pd.bantime(),pd.banreason().data(),pd.serverid(),pd.fromserverid(),pd.gmlv());
                //logInfo("__saveBaseData__saveBaseData1111111111 %llu %d", pid, opt);
                ps->execute();
                //logInfo("__saveBaseData__saveBaseData2222222222%llu %d", pid, opt);
            }            
        }
    }
    catch (sql::SQLException &e)
    {
        logInfo("__saveBaseData %llu %s", pid, e.what());
    }


}

static inline void reqSaveBaseData2Db(char *data, size_t len)
{
    ReqSavePlayerBaseData req;
    req.ParseFromArray(data, len);

    uint64_t pid = req.pid();
    auto pd = req.data();
    uint8_t opt = req.opt();

    __saveBaseData(pd, pid, opt);
}


static inline void reqSaveModuleData2Db(char *data, size_t len)
{
    ReqSavePlayerModuleData req;
    req.ParseFromArray(data, len);

    //logInfo("reqSaveModuleData2Db");
    uint64_t pid = req.pid();
    uint16_t serverId = req.serverid();
    uint8_t moduleId = req.moduleid();

    __saveModuleData(pid, moduleId, req.data(), serverId);
}

static inline uint8_t updatePlayerFistLoginTime(uint64_t pid)
{
    auto con = gMysqlClient.getMysqlCon();
    if(!con)
    {
        logInfo("updatePlayerFistLoginTime ps err %lu", pid);
        return ServerErrorCode::CreateSqlError;
    }

    uint8_t ret = 0;
    try
    {
        std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("update actors set firstlogintime=from_unixtime(?) where pid=?"));
        if (!ps)
        {
            return ServerErrorCode::CreateSqlError;
        }

        ps->setUInt(1, gTools.getNowTime());
        ps->setUInt64(2, pid);
        ps->execute();
    }
    catch (sql::SQLException &e)
    {
        logInfo(e.what());
        ret = ServerErrorCode::UpdateTimeError;
    }
    

    return ret;
}

static inline void regPlayerBaseInfo2Db(char *data, size_t len)
{
    PlayerBaseData req;
    req.ParseFromArray(data, len); 

    auto con = gMysqlClient.getMysqlCon();
    if(!con)
    {
        logInfo("updatePlayerInfo err");
        return;
    }

    uint64_t pid = req.pid();

    try
    {
        std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("insert into actors(pid,name,account,level,vip,serverid,icon,title,headicon,skin,power,guildid,sex) values (?,?,?,?,?,?,?,?,?,?,?,?,?)"));
        if (!ps)
        {
            logInfo("updatePlayerInfo ps error2");
        }
        else
        {
            ps->setUInt64(1, pid);
            ps->setString(2, req.name());
            ps->setString(3, req.account());
            ps->setUInt(4, req.level());
            ps->setUInt(5, req.vip());
            ps->setUInt(6, req.serverid());
            ps->setString(7, req.icon());
            ps->setUInt(8, req.title());
            ps->setUInt(9, req.headicon());
            ps->setUInt(10, req.skin());
            ps->setUInt(11, req.power());
            ps->setUInt64(12, req.guildid());
            ps->setUInt(13, req.sex());
            ps->execute();
        }
    }
    catch(sql::SQLException &e)
    {
        logInfo(e.what());
    }

}

static inline void __saveRankData(const std::string& name, const std::string& data, int rankLen, uint16_t serverId)
{

    auto con = gMysqlClient.getMysqlCon();
    if(!con)
    {
        logInfo("__saveRankData err %s", name.c_str());
        return;
    }

    try
    {
        std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("replace into rank(name,data,ranklen,serverid)values(?,?,?,?)"));
        if (!ps)
        {
            logInfo("__saveRankData err %s", name.c_str());
        }
        else
        {
            ps->setString(1, name);
            ps->setString(2, data);
            ps->setInt(3, rankLen);
            ps->setInt(4, serverId);
            ps->execute();
        }
    }
    catch (sql::SQLException &e)
    {
        logInfo(e.what());
    }

 
}

static inline void __delRankData(const std::string& name, uint16_t serverId)
{
    auto con = gMysqlClient.getMysqlCon();
    if(!con)
    {
        logInfo("__delRankData err %s", name.data());
        return;
    }

    try
    {

        std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("delete from rank where name=? and serverid = ?"));
        if (!ps)
        {
            logInfo("__delRankData err %s", name.data());
        }
        else
        {
            ps->setString(1, name);
            ps->setUInt(2, serverId);         
            ps->execute();
        }

    }
    catch (sql::SQLException &e)
    {
        logInfo(e.what());
    }    

}


static inline void __saveGlobalData(uint8_t moduleId, const std::string& data, uint16_t serverId)
{

    auto con = gMysqlClient.getMysqlCon();
    if(!con)
    {
        logInfo("__saveGlobalData ps err %d", moduleId);
        return;
    }

    try
    {
        std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("replace into globaldata(moduleid,data,serverid)values(?,?,?)"));

        if (!ps)
        {
            logInfo("__saveGlobalData ps err %d", moduleId);
        }
        else
        {
            ps->setInt(1, moduleId);
            ps->setString(2, data);
            ps->setInt(3, serverId);
            ps->execute();
        }

    }
    catch (sql::SQLException &e)
    {
        logInfo(e.what());
    }
}