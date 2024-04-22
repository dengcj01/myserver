
#include "msgHandle.h"
#include <string.h>
#include <iostream>
#include <iomanip>
#include "../../../common/MysqlClient.h"
#include "../../../common/log/Log.h"
#include "../../../../libs/mysql/mysql_connection.h"
#include "../../../../libs/mysql/mysql_error.h"
#include "../../../../libs/mysql/cppconn/resultset.h"
#include "../../../../libs/mysql/cppconn/statement.h"
#include "../../../../libs/mysql/cppconn/prepared_statement.h"

#include "../../../common/pb/ServerCommon.pb.h"
#include "../../../common/net/Data.h"
#include "../MainThread.h"
#include "../GameLog.hpp"

void writeLogData(uint64_t sessionId, char *data, size_t len)
{
    WriteLogData wd;
    wd.ParseFromArray(data, len);
    gGameLog.write(wd, time(0));


}

void writeMailData(uint64_t sessionId, char *data, size_t len)
{
    WriteMailData wd;
    wd.ParseFromArray(data, len);
    gGameLog.write(wd, time(0));
}

void reqGameQuit(uint64_t sessionId, char *data, size_t len)
{
    gMainThread.closeServer();
}

void dispatchClientMessage(uint16_t messageId, uint64_t sessionId, char *data, size_t len)
{
    logInfo("dispatchClientMessage %d", messageId);
    switch (messageId)
    {
    case 1:
    {
        writeLogData(sessionId, data, len);
        break;
    }
    case 2:
    {
        writeMailData(sessionId, data, len);
        break;
    }
    case 255:
    {
        reqGameQuit(sessionId, data, len);
        break;
    }
    default:
        break;
    }
}
