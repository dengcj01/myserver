

#include <iostream>
#include <signal.h>

#include "MainThread.h"
#include "../../common/log/Log.h"
#include "../../common/Tools.hpp"
#include "../../common/ParseConfig.hpp"
#include "GameLog.hpp"

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

		logPath.append("loglog/");
		logInit(logPath.c_str(), "log.log");

		struct sigaction act;
		memset(&act, 0, sizeof(act));
		act.sa_handler = sigHandle;
		sigaction(SIGPIPE | SIGINT, &act, 0);

		std::string path = gTools.getParen2tPath(parentPath);

		gGameLog.init(path);
	}

	gMainThread.start(gParseConfig.serverPort_);

	return 0;
}