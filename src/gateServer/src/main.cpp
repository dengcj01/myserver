

#include <unistd.h>
#include <iostream>
#include <signal.h>
#include <time.h>
#include "MainThread.h"
#include "../../common/net/Data.h"
#include "../../common/net/TcpServer.h"
#include "MainThread.h"
#include "../../common/log/Log.h"

#include "../../common/Timer.hpp"
#include "../../common/Tools.hpp"
std::atomic<bool> cmdStopFlag(false);


void sigHandle(int sig)
{
}

int main(int argc, char **argv)
{

	{

		const char *cfg = nullptr;
		if (argc > 1)
		{
			cfg = argv[1];
		}

		std::string exePath = gTools.getAbsolutePath(argv[0]);	// data/home/normal/develop/server/server_1/game/wxgame_20230704_3
		std::string parentPath = gTools.getParentPath(exePath); // /data/home/normal/develop/server/server_1/game/

		std::string logPath = gTools.getParen2tPath(parentPath);


		gParseConfig.parseConfig(parentPath, cfg);

		if (gParseConfig.daemon_)
		{
			daemon(1, 0);

		}

		logPath.append("gatelog/");
		logInit(logPath.c_str(), "gate");

		// logInfo("%s  %s", exePath.c_str(), parentPath.c_str());

		struct sigaction act;
		memset(&act, 0, sizeof(act));
		act.sa_handler = sigHandle;
		sigaction(SIGPIPE | SIGINT, &act, 0);

		gTimer.init();

	}

	gMainThread.start(gParseConfig.serverPort_);
	return 0;
}