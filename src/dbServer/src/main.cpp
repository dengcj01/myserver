

#include <iostream>
#include <signal.h>
#include <string.h>
#include "MainThread.h"
#include "../../common/log/Log.h"
#include "../../common/Tools.hpp"

#include "../../common/MysqlClient.h"
#include "../../common/Timer.hpp"
#include "../../common/ParseConfig.hpp"

void sigHandle(int sig)
{
}

int main(int argc, char **argv)
{
	{
		std::string exePath = gTools.getAbsolutePath(argv[0]);
		std::string parentPath = gTools.getParentPath(exePath);

		std::string logPath = gTools.getParen2tPath(parentPath);

		gParseConfig.parseConfig(parentPath);
		if (gParseConfig.daemon_)
		{
			daemon(1, 0);
		}

		logPath.append("dblog/");
		logInit(logPath.c_str(), "log.log");

		gMysqlClient.initDb(gParseConfig.dbIp_.data());
		gMysqlClient.initGlobalDb(gParseConfig.glbaldataDbIp_.data());

		gTimer.init();

		struct sigaction act;
		memset(&act, 0, sizeof(act));
		act.sa_handler = sigHandle;
		sigaction(SIGPIPE | SIGINT, &act, 0);

	}

	gMainThread.start(gParseConfig.serverPort_);

	return 0;
}