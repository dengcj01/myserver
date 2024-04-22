
#include <unistd.h>
#include <iostream>
#include <signal.h>
#include <time.h>

#include "MainThread.h"
#include "../../common/net/Data.h"
#include "../../common/net/TcpServer.h"
#include "script/Script.h"
#include "MainThread.h"

#include "../../common/log/Log.h"
#include "../../common/Timer.hpp"
#include "../../common/Tools.hpp"
#include "../../common/ParseConfig.hpp"

#include "../../common/MysqlClient.h"
#include "../../common/Rank.hpp"
#include "../../common/Filter.hpp"
#include "configparse/CfgMgr.h"
#include "fight/FightMgr.h"


extern google::protobuf::compiler::DiskSourceTree g_sourceTree;
extern std::unordered_map<uint8_t, Client *> gServerClients;

void sigpipeHandle(int sig)
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

		logPath.append("gamelog/");
		logInit(logPath.c_str(), "log.log");

		gMysqlClient.initDb(gParseConfig.dbIp_.data());
		gMysqlClient.initGlobalDb(gParseConfig.glbaldataDbIp_.data());

		gParseConfig.parseCrossConfig();

		//logInfo("%s  %s", exePath.c_str(), parentPath.c_str()); // /data/home/gameServerProject/src/gameServer/bin/game  /data/home/gameServerProject/src/gameServer/bin/

		struct sigaction act;
		memset(&act, 0, sizeof(act));
		act.sa_handler = sigpipeHandle;
		sigaction(SIGPIPE, &act, 0);

		std::string protobufPath = gTools.getParen2tPath(parentPath);
		protobufPath.append("protobuf");

		g_sourceTree.MapPath("", protobufPath.data());

		//gCfgMgr.loadJsonCfg(parentPath);

		gTimer.init();

		if (gParseConfig.isGameServer())
		{
			gFilter.init();
			gMainThread.initNames(parentPath);
		}

		gRankMgr.loadRankData();

		gScript.openLua(parentPath.data());

		gMainThread.loadGlobalData();

		//gFightMgr.init();

		

	}

	gMainThread.start(gParseConfig.serverPort_);

	return 0;
}