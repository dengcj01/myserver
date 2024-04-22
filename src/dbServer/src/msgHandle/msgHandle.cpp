
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
#include "../../../common/pb/ServerCommon.pb.h"
#include "../MainThread.h"
#include "../../../common/LoadPlayerData.hpp"
#include "../../../common/CommDefine.h"

void reqDbLoginAuth(uint64_t sessionId, char *data, size_t len)
{
    ReqDbLoginAuth req;
    req.ParseFromArray(data, len);

    ResDbLoginAuth res;
    res.set_account(req.account());
    res.set_pf(req.pf());
    res.set_code(0);
    res.set_fromserverid(req.fromserverid());
    res.set_csessionid(req.csessionid());
    res.set_sessionid(req.sessionid());
    //logInfo("reqDbLoginAuth %llu %llu", req.csessionid(),req.sessionid());

    sql::PreparedStatement *ps = nullptr;

    try
    {
        ps = gMysqlClient.getMysqlCon()->prepareStatement(queryaccount);
        ps->setString(1, req.account());
        ps->setString(2, req.pf());
        ps->setInt(3, req.fromserverid());

        sql::ResultSet *rst = ps->executeQuery();
        bool ok = false;
        std::string passwd;
        int closed = 0;

        while (rst->next())
        {
            ok = true;
            res.set_account(rst->getString("account"));
            res.set_gmlv(rst->getInt("gmlevel"));
            res.set_pf(rst->getString("pf"));
            closed = rst->getInt("closed");
            res.set_fcmtime(rst->getInt("fcmonline"));
            passwd = rst->getString("passwd");
        }

        delete rst;
        ps->getMoreResults();
        delete ps;

        if (ok)
        {
            if (req.password().size() > 0 && passwd != req.password())
            {
                res.set_code(serverpasswderr);
            }
            else
            {
                if (closed == 1)
                {
                    res.set_code(serverbanacccount);
                }
                else if (closed == 2)
                {
                    res.set_code(serverbanip);
                }
            }
        }
        else
        {
            res.set_code(servernoacccount);
        }
    }
    catch (sql::SQLException &e)
    {
        res.set_code(serverdbautherr);
        logInfo(e.what());
    }

    gMainThread.send2Game(res, g2dResDbLoginAuth, sessionId);
}

void reqDbSelectPlayer(uint64_t sessionId, char *data, size_t len)
{
    ReqDbSelectPlayer req;
    req.ParseFromArray(data, len);

    ResDbSelectPlayer res;
    res.set_pid(0);
    res.set_csessionid(req.csessionid());
    res.set_sessionid(req.sessionid());
    sql::PreparedStatement *ps = nullptr;

    try
    {
        ps = gMysqlClient.getMysqlCon()->prepareStatement(queryactors);
        ps->setString(1, req.account());
        ps->setString(2, req.pf());
        ps->setInt(3, req.fromserverid());

        sql::ResultSet *rst = ps->executeQuery();
        while (rst->next())
        {
            res.set_pid(rst->getUInt64("pid"));
        }
        delete rst;
        ps->getMoreResults();
        delete ps;
    }
    catch (sql::SQLException &e)
    {
        logInfo(e.what());
        res.set_code(serverdbselecterr);
    }
    gMainThread.send2Game(res, g2dResDbSelectPlayer, sessionId);
}

void reqDbCreatePlayer(uint64_t sessionId, char *data, size_t len)
{
    ReqDbCreatePlayer req;
    req.ParseFromArray(data, len);

    ResDbCreatePlayer res;
    res.set_pid(req.pid());

    res.set_sex(req.sex());
    res.set_code(0);
    res.set_name(req.name());
    res.set_csessionid(req.csessionid());
    res.set_sessionid(req.sessionid());

    sql::PreparedStatement *ps = nullptr;
    try
    {
        ps = gMysqlClient.getMysqlCon()->prepareStatement("select count(*) as cnt from actors where account=? and pf=? and fromserverid=?");
        ps->setString(1, req.account());
        ps->setString(2, req.pf());
        ps->setInt(3, req.fromserverid());

        sql::ResultSet *rst = ps->executeQuery();
        while (rst->next())
        {
            if (rst->getInt("cnt") > 0)
            {
                res.set_code(serveraccountexists);
            }
        }
        delete rst;
        delete ps;
    }
    catch (sql::SQLException &e)
    {
        logInfo(e.what());
        res.set_code(serveraccountexistsdb);
    }

    if (res.code() == 0)
    {
        try
        {
            ps = gMysqlClient.getMysqlCon()->prepareStatement("insert into usedname(name)values(?)");
            ps->setString(1, res.name());
            ps->execute();
            delete ps;

            ps = gMysqlClient.getMysqlCon()->prepareStatement(insertactor);
            ps->setUInt64(1, req.pid());
            ps->setString(2, req.name());
            ps->setString(3, req.account());
            ps->setString(4, req.pf());
            ps->setInt(5, time(0));
            ps->setInt(6, req.serverid());
            ps->setInt(7, req.fromserverid());

            ps->execute();
            delete ps;
        }
        catch (sql::SQLException &e)
        {
            logInfo(e.what());
            res.set_code(serverdbcreateerr);
        }
    }

    gMainThread.send2Game(res, g2dResDbCreatePlayer, sessionId);
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
    if (ret == 0)
    {
        gMainThread.send2Game(rb, g2dResReturnPlayerBaseData, sessionId);

        ResReturnPlayerBagData rp;
        rp.set_pid(pid);
        rp.set_csessionid(csessionId);
        rp.set_sessionid(sessionId1);
        ret = loadPlayerBagData(pid, rp);

        if (ret == 0)
        {
            gMainThread.send2Game(rp, g2dResReturnPlayerBagData, sessionId);
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
                    gMainThread.send2Game(rm, g2dResReturnPlayerModuleData, sessionId);
                }

                updatePlayerLoginTime(pid);
            }
        }
    }

    ResDbEnterGame res;
    res.set_pid(req.pid());
    res.set_code(ret);
    res.set_csessionid(csessionId);
    res.set_sessionid(sessionId1);
    gMainThread.send2Game(res, g2dResDbEnterGame, sessionId);

}

void reqGameQuit(uint64_t sessionId, char *data, size_t len)
{
    gMainThread.closeServer();
}

void dispatchClientMessage(uint16_t messageId, uint64_t sessionId, char *data, size_t len)
{
    logInfo("dispatchGameClientMessage %d", messageId);
    switch (messageId)
    {
    case g2dReqDbLoginAuth:
        reqDbLoginAuth(sessionId, data, len);
        break;
    case g2dReqDbSelectPlayer:
        reqDbSelectPlayer(sessionId, data, len);
        break;
    case g2dReqDbCreatePlayer:
        reqDbCreatePlayer(sessionId, data, len);
        break;
    case g2dReqDbEnterGame:
        reqDbEnterGame(sessionId, data, len);
        break;
    case g2dReqSavePlayerBagData:
        saverBagData2Db(data, len);
        break;
    case g2dReqSavePlayerBaseData:
        saveBaseData2Db(data, len);
        break;
    case g2dReqSavePlayerModuleData:
        saveModuleData2Db(data, len);
        break;
    case 255:
        reqGameQuit(sessionId, data, len);
        break;
    default:
        break;
    }
}
