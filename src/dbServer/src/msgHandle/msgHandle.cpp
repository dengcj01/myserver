
#include "msgHandle.h"
#include <string.h>
#include <time.h>

#include "../../../common/MysqlClient.h"
#include "../../../common/log/Log.h"
#include "../../../../libs/mysql/mysql_connection.h"
#include "../../../../libs/mysql/mysql_error.h"
#include "../../../../libs/mysql/cppconn/resultset.h"
#include "../../../../libs/mysql/cppconn/statement.h"
#include "../../../../libs/mysql/cppconn/prepared_statement.h"
#include "../../../common/net/Data.h"
#include "../MainThread.h"
#include "../../../common/LoadPlayerData.hpp"
#include "../../../common/CommDefine.h"
#include "../../../common/pb/Server.pb.h"
#include "../../../common/ProtoIdDef.h"

void reqDbSelectPlayer(uint64_t sessionId, char *data, size_t len)
{
    ReqDbSelectPlayer req;
    req.ParseFromArray(data, len);

    ResDbSelectPlayer res;
    res.set_pid(ServerErrorCode::Success);
    res.set_csessionid(req.csessionid());
    res.set_sessionid(req.sessionid());

    auto con = gMysqlClient.getMysqlCon();
    if(!con)
    {
        logInfo("reqDbSelectPlayer err %s", req.account());
        res.set_code(ServerErrorCode::DbSelectError);
    }
    else
    {
        try
        {
            std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("select pid from actors where account=? and pf=? and fromserverid=?"));
            if (!ps)
            {
                logInfo("reqDbSelectPlayer ps error");
                res.set_code(ServerErrorCode::CreateSqlError);
            }
            else
            {
                ps->setString(1, req.account());
                ps->setString(2, req.pf());
                ps->setInt(3, req.fromserverid());

                std::unique_ptr<sql::ResultSet> rst = std::unique_ptr<sql::ResultSet>(ps->executeQuery());
                if (!rst)
                {
                    logInfo("reqDbSelectPlayer rst error");
                    res.set_code(ServerErrorCode::CreateSqlError);
                }
                else
                {
                    while (rst->next())
                    {
                        res.set_pid(rst->getUInt64("pid"));
                    }
                }
            }
        }
        catch (sql::SQLException &e)
        {
            logInfo(e.what());
            res.set_code(ServerErrorCode::DbSelectError);
        }
    }

    gMainThread.send2Game(res, (int16_t)ProtoIdDef::ResDbSelectPlayer, sessionId);
}

void reqDbCreatePlayer(uint64_t sessionId, char *data, size_t len)
{
    ReqDbCreatePlayer req;
    req.ParseFromArray(data, len);

    ResDbCreatePlayer res;
    res.set_pid(req.pid());

    uint8_t sex = req.sex();
    res.set_sex(sex);
    res.set_code(ServerErrorCode::Success);
    res.set_name(req.name());
    res.set_csessionid(req.csessionid());
    res.set_sessionid(req.sessionid());

    int fromServerId = req.fromserverid();

    auto con = gMysqlClient.getMysqlCon();
    if(!con)
    {
        logInfo("reqDbCreatePlayer err %s", req.account());
        res.set_code(ServerErrorCode::DbCreateError);
    }
    else
    {
        try
        {
            std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("select count(*) as cnt from actors where account=? and pf=? and fromserverid=?"));
            if (!ps)
            {
                logInfo("reqDbCreatePlayer ps error");
                res.set_code(ServerErrorCode::CreateSqlError);
            }
            else
            {
                ps->setString(1, req.account());
                ps->setString(2, req.pf());
                ps->setInt(3, fromServerId);

                std::unique_ptr<sql::ResultSet> rst = std::unique_ptr<sql::ResultSet>(ps->executeQuery());

                if (!rst)
                {
                    logInfo("reqDbCreatePlayer rst error");
                    res.set_code(ServerErrorCode::CreateSqlError);
                }
                else
                {
                    while (rst->next())
                    {
                        if (rst->getInt("cnt") > 0)
                        {
                            res.set_code(ServerErrorCode::AccountExists);
                        }
                    }
                }
            }
        }
        catch (sql::SQLException &e)
        {
            logInfo(e.what());
            res.set_code(ServerErrorCode::AccountExistsDb);
        }

        if (res.code() == 0)
        {
            try
            {
                bool ok1 = true;
                std::unique_ptr<sql::PreparedStatement> ps1 = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("select count(*) as cnt from usedname where name=?"));
                if(!ps1)
                {
                    logInfo("reqDbCreatePlayer ps1 error1");
                    res.set_code(ServerErrorCode::CreateSqlError);                    
                }
                else
                {
                    ps1->setString(1, req.name());
                    std::unique_ptr<sql::ResultSet> rst1 = std::unique_ptr<sql::ResultSet>(ps1->executeQuery());
                    if (!rst1)
                    {
                        logInfo("reqDbCreatePlayer rst1 error");
                        res.set_code(ServerErrorCode::CreateSqlError);
                    } 
                    else
                    {
                        while (rst1->next())
                        {
                            if (rst1->getInt("cnt") > 0)
                            {
                                res.set_code(ServerErrorCode::NameRepeated);
                                ok1 = false;
                                break;
                            }
                        }

                        if(ok1)
                        {
                            std::unique_ptr<sql::PreparedStatement> ps2 = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("insert into usedname(name)values(?)"));
                            if (!ps2)
                            {
                                logInfo("reqDbCreatePlayer ps error1");
                                res.set_code(ServerErrorCode::CreateSqlError);
                            }
                            else
                            {
                                ps2->setString(1, res.name());
                                ps2->execute();
                            }

                            std::unique_ptr<sql::PreparedStatement> ips = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("insert into actors(pid, name, account, pf, createtime,serverid,fromserverid,sex) values(?, ?, ?, ?, from_unixtime(?),?,?,?)"));
                            if (!ips)
                            {
                                logInfo("reqDbCreatePlayer ips error2");
                                res.set_code(ServerErrorCode::CreateSqlError);
                            }
                            else
                            {
                                ips->setUInt64(1, req.pid());
                                ips->setString(2, req.name());
                                ips->setString(3, req.account());
                                ips->setString(4, req.pf());
                                ips->setInt(5, gTools.getNowTime());
                                ips->setInt(6, req.serverid());
                                ips->setInt(7, fromServerId);
                                ips->setInt(8, sex);

                                ips->execute();
                            }
                        }                    
                    }                   
                }
            }
            catch (sql::SQLException &e)
            {
                logInfo(e.what());
                res.set_code(ServerErrorCode::DbCreateError);
            }
        }
    }


    gMainThread.send2Game(res, (uint16_t)ProtoIdDef::ResDbCreatePlayer, sessionId);
}

void reqDbEnterGame(uint64_t sessionId, char *data, size_t len)
{
    ReqDbEnterGame req;
    req.ParseFromArray(data, len);

    uint64_t pid = req.pid();

    ResReturnPlayerBaseData rb;
    uint64_t csessionId = req.csessionid();
    uint64_t sessionId1 = req.sessionid();
    rb.set_csessionid(csessionId);
    rb.set_pid(pid);
    rb.set_sessionid(sessionId1);

    auto md = rb.mutable_data();
    uint8_t ret = loadPlayerBaseData(pid, *md);

    uint32_t nowTime = gTools.getNowTime();
    ResDbEnterGame res;

    //logInfo("reqDbEnterGamereqDbEnterGame %d %d", nowTime, md->bantime());

    if (ret == 0)
    {
        if(nowTime < md->bantime())
        {
            ret = ServerErrorCode::BannedAccount;
        }
        else
        {   
            bool up = true;
            if(md->bantime() > 0)
            {
                md->set_bantime(0);
                md->set_banreason("");  

                {
                    auto con = gMysqlClient.getMysqlCon();
                    if(!con)
                    {
                        res.set_code(ServerErrorCode::DbErrorBase);
                        up = false;
                        logInfo("reqDbEnterGame err11 no con");
                    }  
                    else
                    {
                        try
                        {
                            std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("update actors set banTime=from_unixtime(?),banreason=? where pid=?"));
                            if (!ps)
                            {
                                logInfo("reqDbEnterGame ps11 err %lu", pid);
                                res.set_code(ServerErrorCode::DbErrorBase);
                                up = false;
                            }
                            else
                            {
                                ps->setNull(1, sql::DataType::SQLNULL);
                                ps->setString(2, "");   
                                ps->setUInt64(3, pid); 
                                
                                ps->execute();                    
                            }
                        }     
                        catch(sql::SQLException &e)
                        {
                            res.set_code(ServerErrorCode::DbErrorBase);
                            up = false;
                            logInfo("reqDbEnterGame %llu %s", pid, e.what());                       
                        }
                    }         
                }
            }

            if(up)
            {
                gMainThread.send2Game(rb, (uint16_t)ProtoIdDef::ResReturnPlayerBaseData, sessionId);

                std::map<uint8_t, std::string> md;
                ret = loadPlayerModuleData(pid, md);
                if (ret == 0)
                {
                    for (auto e : md)
                    {
                        ResReturnPlayerModuleData rm;
                        rm.set_moduleid(e.first);
                        rm.set_data(e.second);
                        rm.set_csessionid(csessionId);
                        rm.set_sessionid(sessionId1);
                        gMainThread.send2Game(rm, (uint16_t)ProtoIdDef::ResReturnPlayerModuleData, sessionId);
                    }

                    updatePlayerFistLoginTime(pid);
                }
            }
        }
    }

    //logInfo("22222222222222222222");

    res.set_pid(req.pid());
    res.set_code(ret);
    res.set_csessionid(csessionId);
    res.set_sessionid(sessionId1);
    gMainThread.send2Game(res, (uint16_t)ProtoIdDef::ResDbEnterGame, sessionId);
}


void reqGameQuit(uint64_t sessionId, char *data, size_t len)
{
    gMainThread.closeServer();
}

void reqSaveRankData(char *data, size_t len)
{
    ReqSaveRankData req;
    req.ParseFromArray(data, len);

    __saveRankData(req.name(), req.data(), req.ranklen(), req.serverid());
}

void reqSaveGlobalData(char *data, size_t len)
{
    ReqSaveGlobalData req;
    req.ParseFromArray(data, len);

    __saveGlobalData(req.moduleid(), req.data(), req.serverid());

}

void reqDelRankData(char *data, size_t len)
{
    ReqDelRankData req;
    req.ParseFromArray(data, len);
    __delRankData(req.name(), req.serverid());
}


void reqDbUpdatePlayerName(uint64_t sessionId, char *data, size_t len)
{
    ReqDbUpdatePlayerName rn;
    rn.ParseFromArray(data, len);
    const std::string& name = rn.name();

    uint64_t pid = rn.pid();

    ResDbUpdatePlayerName res;

    res.set_name(name);
    res.set_pid(pid);
    uint8_t code = 0;

    auto con = gMysqlClient.getMysqlCon();
    if(!con)
    {
        logInfo("reqDbUpdatePlayerName err1", pid);
        code = 1;
    }
    else
    {
        try
        {
            std::unique_ptr<sql::PreparedStatement> ps1 = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("select count(*) as cnt from usedname where name=?"));
            if (!ps1)
            {
                logInfo("reqDbUpdatePlayerName ps1", pid);
                code = 1;
            }
            else
            {
                ps1->setString(1, name);
                std::unique_ptr<sql::ResultSet> rst1 = std::unique_ptr<sql::ResultSet>(ps1->executeQuery());
                if (!rst1)
                {
                    logInfo("reqDbUpdatePlayerName rst1 error", pid);
                    code = 1;
                } 
                else
                {
                    while (rst1->next())
                    {
                        if (rst1->getInt("cnt") > 0)
                        {
                            code = 1;
                            break;
                        }
                    }

                    if(code == 0)
                    {
                        std::unique_ptr<sql::PreparedStatement> ps2 = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("insert into usedname(name)values(?)"));
                        if (!ps2)
                        {
                            logInfo("reqDbUpdatePlayerName ps2 error", pid);
                            code = 1;
                        }
                        else
                        {
                            ps2->setString(1, name);
                            ps2->execute();
                        }                        
                    }
                }
            }
        }
        catch (sql::SQLException &e)
        {
            code = 1;
            logInfo(e.what());
        }  
    }
    
    res.set_code(code);
    gMainThread.send2Game(res, (uint16_t)ProtoIdDef::ResDbUpdatePlayerName, sessionId);
}

void reqUpdatePlayerBaseInfo(char *data, size_t len)
{
    ReqUpdatePlayerBaseInfo rd;
    rd.ParseFromArray(data, len);
    uint64_t pid = rd.pid();

    auto con = gMysqlClient.getMysqlCon();
    if(!con)
    {
        logInfo("reqUpdatePlayerBaseInfo ps err %lu", pid);
        return;
    }


    nlohmann::json j;
    try
    {
        j = nlohmann::json::parse(rd.data());
    }
    catch(const nlohmann::json::parse_error& e)
    {
        logInfo("reqUpdatePlayerBaseInfo err %llu %s", pid, e.what());
        return;
    }

    
    std::string str= "update actors set ";

	uint8_t lens = j.size();
    uint8_t idx = lens - 1;
    uint8_t readLen = 0;

    nlohmann::json jsonData = nlohmann::json::array(); 

    for (uint8_t i = 0; i < lens; i++) 
	{
		nlohmann::json obj = j[i];
        nlohmann::json tmp;
        for (auto it = obj.begin(); it != obj.end(); ++it) 
		{
            const std::string s = gTools.toLowerCase(it.key());
            const char* key = s.data();
            int type = gMainThread.getDbKeyType(pid, key);
            if(type == 0)
            {
                break;;
            }

			str.append(s);
			str.append("=");
            if(type == 4) // 时间戳
            {
                str.append("from_unixtime(?)");
            }              
            else
            {
                str.append("?");
            }

			if(i != idx)
			{
				str.append(",");
			}
			readLen += 1;
            tmp[key] = it.value();
            jsonData.emplace_back(tmp);
            break;
        }
    }

	str.append(" where pid = ?");

    // logInfo("xxxxxxxxxxxxxx %d %s", readLen, str.data());
    // logInfo("AAAAAAAAAAA %s",jsonData.dump().data()); 
    try
    {
        std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement(str));
        for (uint8_t i = 0; i< readLen; i++) 
        {
            nlohmann::json obj = jsonData[i];
            uint8_t idx = i + 1;
            for (auto it = obj.begin(); it != obj.end(); ++it) 
            {
                const char* key = it.key().data();
                int type = gMainThread.getDbKeyType(pid, key);
                if(type == OfflineDbKeyDef::OfflineDbKeyDefString) // 字符串
                {
                    std::string val = it.value();
                    ps->setString(idx, val);
                }
                else if(type == OfflineDbKeyDef::OfflineDbKeyDefInt) // int
                {
                    uint32_t val = it.value();
                    ps->setUInt(idx, val);
                }
                else if(type == OfflineDbKeyDef::offlinedbkeydefint64) // int64
                {
                    uint64_t val = it.value();
                    ps->setUInt64(idx, val);
                }                
                else if(type == OfflineDbKeyDef::offlinedbkeydeftime) // 时间戳
                {
                    uint32_t val = it.value();
                    if(val == 0)
                    {
                        ps->setNull(idx, sql::DataType::SQLNULL);
                    }
                    else
                    {
                        ps->setUInt(idx, val);
                    }
                    
                }                 
                else
                {
                    logInfo("reqUpdatePlayerBaseInfo err %llu %s", pid, key);
                }
            }
        }
        ps->setUInt64(readLen + 1, pid);
        ps->execute();
    }
    catch (sql::SQLException &e)
    {
        logInfo(e.what());
    }  

}


void dispatchClientMessage(uint16_t messageId, uint64_t sessionId, char *data, size_t len)
{
    logInfo("dispatchClientMessagedispatchClientMessagedispatchClientMessage111111111 %d", messageId);
    switch (messageId)
    {
    case (uint16_t)ProtoIdDef::ReqDbSelectPlayer:
        reqDbSelectPlayer(sessionId, data, len);
        break;
    case (uint16_t)ProtoIdDef::ReqDbCreatePlayer:
        reqDbCreatePlayer(sessionId, data, len);
        break;
    case (uint16_t)ProtoIdDef::ReqDbEnterGame:
        reqDbEnterGame(sessionId, data, len);
        break;



    case (uint16_t)ProtoIdDef::ReqDbUpdatePlayerName:
        reqDbUpdatePlayerName(sessionId, data, len);
        break;
    case (uint16_t)ProtoIdDef::ReqUpdatePlayerBaseInfo:
        reqUpdatePlayerBaseInfo(data, len);
        break;

    case (uint16_t)ProtoIdDef::ReqSavePlayerBaseData:
        reqSaveBaseData2Db(data, len);
        break;
    case (uint16_t)ProtoIdDef::ReqSavePlayerModuleData:
        reqSaveModuleData2Db(data, len);
        break;
     case (uint16_t)ProtoIdDef::ReqSaveRankData:
        reqSaveRankData(data, len);
        break;      
    case (uint16_t)ProtoIdDef::ReqSaveGlobalData:
        reqSaveGlobalData(data, len);
        break; 
    case (uint16_t)ProtoIdDef::ReqDelRankData: 
        reqDelRankData(data, len);
        break;   
    case (uint16_t)ProtoIdDef::ReqRegPlayerBaseInfo:
        regPlayerBaseInfo2Db(data, len);
        break;                          
    case (uint16_t)ProtoIdDef::ReqCloseDbServer:
        reqGameQuit(sessionId, data, len);
        break;
    default:
        break;
    }
    logInfo("dispatchClientMessagedispatchClientMessagedispatchClientMessage22222222222 %d", messageId);
}
