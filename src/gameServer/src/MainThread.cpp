

#include "MainThread.h"
#include <atomic>
#include <pthread.h>
#include <chrono>
#include <unistd.h>
#include <sstream>
#include <iostream>
#include <regex>
#include <sys/syscall.h>
#include <algorithm>
#include <iostream>
#include <fstream>
#include <memory>
#include <netdb.h>

#include "player/Player.h"
#include "player/PlayerMgr.h"

#include "../../common/net/EventLoop.h"
#include "../../common/net/TcpConnecter.h"
#include "../../common/Timer.hpp"
#include "../../common/log/Log.h"
#include "../../common/Tools.hpp"
#include "../../common/CommDefine.h"
#include "../../common/Client.h"
#include "../../common/Json.hpp"
//#include "../../../libs/jemalloc/jemalloc.h"
#include "msgHandle/msgHandle.h"
#include "script/Script.h"
#include "../../common/MysqlClient.h"
#include "../../../libs/mysql/mysql_connection.h"
#include "../../../libs/mysql/mysql_error.h"
#include "../../../libs/mysql/cppconn/resultset.h"
#include "../../../libs/mysql/cppconn/statement.h"
#include "../../../libs/mysql/cppconn/prepared_statement.h"
#include "../../common/ParseConfig.hpp"
#include "public/Rank.hpp"
#include "../../../libs/google/protobuf/dynamic_message.h"
#include "../../../libs/google/protobuf/compiler/importer.h"
#include "../../common/pb/Login.pb.h"
#include "../../common/pb/Server.pb.h"
#include "../../common/Timer.hpp"
#include "../../common/ProtoIdDef.h"
#include "../../../libs/readline/readline.h"



std::unordered_map<uint16_t, MessageBaseInfo> gMessIdMapName;
std::unordered_map<std::string, MessageBaseInfo> gNameMapMessId;

extern google::protobuf::compiler::DiskSourceTree g_sourceTree;
extern google::protobuf::compiler::Importer g_importer;
extern google::protobuf::DynamicMessageFactory g_factory;


extern std::unordered_map<int64_t, TcpConnecter *> gClients;
extern pthread_spinlock_t gsp;
extern std::mutex gMutex;
extern std::queue<Task> gQueue;
extern std::condition_variable gCondVar;
extern std::unordered_map<uint8_t, Client *> gServerClients;

extern std::atomic<bool> cmdStopFlag;


MainThread::~MainThread()
{
}

void MainThread::parseProto(const char *protoName)
{
	if (!g_importer.Import(protoName))
	{
		logQuit("parseProto err, name = %s", protoName);
		_exit(0);
	}
}

void MainThread::coreDump()
{
	int *p = 0;
	*p=100;
}


std::string MainThread::resolveDomain(const std::string &domain) 
{
    struct addrinfo hints, *res;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC; // IPv4 or IPv6
    hints.ai_socktype = SOCK_STREAM;

    int result = getaddrinfo(domain.c_str(), nullptr, &hints, &res);
    if (result != 0) {
        return "";
    }

	std::string ret;
    for (struct addrinfo *p = res; p != nullptr; p = p->ai_next) 
	{
        void *addr;
        std::string ipver;

        // 获取指向内部地址的指针
        if (p->ai_family == AF_INET) { // IPv4
            struct sockaddr_in *ipv4 = reinterpret_cast<struct sockaddr_in *>(p->ai_addr);
            addr = &(ipv4->sin_addr);
            ipver = "IPv4";
        } else { // IPv6
            struct sockaddr_in6 *ipv6 = reinterpret_cast<struct sockaddr_in6 *>(p->ai_addr);
            addr = &(ipv6->sin6_addr);
            ipver = "IPv6";
        }

        // 将 IP 地址从网络字节顺序转换为文本格式
        char ipstr[INET6_ADDRSTRLEN];
        inet_ntop(p->ai_family, addr, ipstr, sizeof(ipstr));
		ret = ipstr;
        
    }

    freeaddrinfo(res); // 释放地址信息
	return ret;
}

bool MainThread::initClient()
{
	//std::string httpIp = resolveDomain("gm-zhujiange.scszsj.com");
	std::string httpIp = "139.224.236.108"; 
	if(httpIp.size() == 0)
	{
		logInfo("parse http err");
		return false;
	}

	if (gParseConfig.isGameServer())
	{
		//uint8_t maxIdx = ConType_game_client;
		uint8_t maxIdx = ConType_db_client;
		for (uint8_t i = ConType::ConType_db_client; i <= maxIdx; i++)
		{

			gServerClients.emplace(i, new Client());
			Client *cli = gServerClients[i];

			if (i == ConType::ConType_db_client)
			{
				cli->init(i, gParseConfig.dbPort_, gParseConfig.dbIp_.data());
			}
			else if (i == ConType::ConType_game_client)
			{
				cli->init(i, gParseConfig.masterPort_, gParseConfig.masterIp_.data());
			}
		}

		// Client *http = new Client();
		// gServerClients.emplace(ConType_http_client, http);
		// http->init(ConType_http_client, 80, httpIp.data());
	}


	if (gParseConfig.isMasterServer())
	{
		gServerClients.emplace(ConType_db_client, new Client());
		Client *cli = gServerClients[ConType_db_client];
		cli->init(ConType_db_client, gParseConfig.dbPort_, gParseConfig.dbIp_.data());
	}

	return true;
}

void MainThread::cacheMessage(uint16_t messageId, const char *lang, const char *name, const char *desc)
{
	gMessIdMapName.emplace(messageId, MessageBaseInfo(messageId, lang, name));
	gNameMapMessId.emplace(name, MessageBaseInfo(messageId, lang, name));
}

typedef void (*FunctionPtr)(uint64_t, uint64_t, char *, size_t);
FunctionPtr MainThread::getProtoFunc(uint16_t messageId)
{
	auto it = cppProto_.find(messageId);
	if (it == cppProto_.end())
	{
		return nullptr;
	}
	return it->second;
}

typedef void (*FunctionPtr1)(uint64_t, char *, size_t);
FunctionPtr1 MainThread::getProtoFunc1(uint16_t messageId)
{
	auto it = cppProto1_.find(messageId);
	if (it == cppProto1_.end())
	{
		return nullptr;
	}
	return it->second;
}

void MainThread::cacheCppProto()
{

	LuaBind::CallLua cl(gScript.l, "gGetCppProto", 1);
	std::map<uint16_t, const char *> data = cl.call<std::map<uint16_t, const char *>, void>();
	for (auto &e : data)
	{
		uint16_t id = e.first;
		const char *name = e.second;		
		if(gParseConfig.isGameServer())
		{
			if (strcmp(name, "ReqLoginAuth") == 0)
			{
				cppProto_[id] = reqLoginAuth;
			}
			if (strcmp(name, "ReqSelectPlayer") == 0)
			{
				cppProto_[id] = reqSelectPlayer;
			}
			if (strcmp(name, "ReqCreatePlayer") == 0)
			{
				cppProto_[id] = reqCreatePlayer;
			}
			if (strcmp(name, "ReqEnterGame") == 0)
			{
				cppProto_[id] = reqEnterGame;
			}
		}
		if(gParseConfig.isMasterServer())
		{
			if (strcmp(name, "ReqRegPlayerBaseInfo") == 0)
			{
				cppProto1_[id] = reqRegPlayerBaseInfo;
			}			
			if (strcmp(name, "ReqUpdatePlayerBaseInfo") == 0)
			{
				cppProto1_[id] = reqUpdatePlayerBaseInfo;
			}		
		}
	}

}

bool MainThread::gLoadPlayers()
{
	//logInfo("gLoadPlayersgLoadPlayersgLoadPlayers");
	nlohmann::json jsonData = nlohmann::json::array(); 
	try
	{

		std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(gMysqlClient.getMysqlCon()->prepareStatement("select * from actors"));
		if (!ps)
		{
			logInfo("loadGlobalData ps err");
			return false;
		}

		std::unique_ptr<sql::ResultSet> rst = std::unique_ptr<sql::ResultSet>(ps->executeQuery());
		if (!rst)
		{
			logInfo("loadGlobalData rst err");
			return false;
		}

		PlayerBaseData pd;
		jsonData = parseBaseDataFromDb(rst, pd, false);
	}
	catch (sql::SQLException &e)
	{
		logInfo(e.what());
		return false;
	}				

	if(!jsonData.empty())
	{
		//logInfo("gLoadPlayersgLoadPlayersgLoadPlayers2");
		const std::string& s = jsonData.dump();
		LuaBind::CallLua cl(gScript.l, "gLoadPlayers");
		cl.call<void, void>(s);	
	}
	return true;
}

void MainThread::start(uint16_t port)
{
	{
		cacheCppProto();
		LuaBind::CallLua cl(gScript.l, "gServerStart");
		cl.call<void, void>();
	}

	

	sqlThread_ = std::thread([&]()
									   {
			while (true)
			{
				checkGm();
				checkClose();
				checkHttpGm();
				if(sqlt_.load())
				{
					break;
				}
				sleep(1);

				Task t;
				t.opt_ = ConType::ConType_one_per_time;

				std::unique_lock<std::mutex> lk(gMutex);
				gQueue.emplace(std::move(t));
				lk.unlock();
				gCondVar.notify_one();

		} });
	sqlThread_.detach();

	{

		uint8_t mod = ConType::ConType_game_server;

		if (gParseConfig.isMasterServer())
		{
			mod = ConType::ConType_master_server;
		}

		bool res = initClient();
		if(!res)
		{
			exit(0);	
		}

		bool cmd = !gParseConfig.daemon_ && (gParseConfig.isGameServer() || gParseConfig.isMasterServer());

		tcp_.start(port, mod, cmd);

	}

	logInfo("-------------------start %s server success ------------------------", gParseConfig.name_.data());
	while (isRunning_)
	{
		std::unique_lock<std::mutex> lk(gMutex);
		while (gQueue.empty())
		{
			gCondVar.wait(lk);
		}

		//logInfo("主线程被唤醒主线程被唤醒主线程被唤醒主线程被唤醒主线程被唤醒主线程被唤醒主线程被唤醒 %d",gQueue.size());
		while (!gQueue.empty())
		{
			qt_.emplace(std::move(gQueue.front()));
			gQueue.pop();
		}

		lk.unlock();

		if (quit_.load())
		{
			logQuit("------------------------quit  game  success------------");
			break;
		}


		while (!qt_.empty())
		{
			Task &t = qt_.front();
			uint8_t opt = t.opt_;

			if (opt == ConType::ConType_game_server)
			{
				processGateClientMessage(t);
			}		
			else if (opt == ConType::ConType_master_server)
			{
				processLogicGameMessage(t);
			}
			else if (opt == ConType::ConType_timer)
			{
				if (t.func_)
				{
					t.func_(t.args_);
					if (t.args_ && t.timerRepeated_ == 0)
					{
						free(t.args_);
						t.args_ = nullptr;
					}
				}
				else
				{
					gScript.callLuaTimer(t.args_->pid_, t.args_->luaFunc_, t.args_->tid_, t.timerRepeated_);
					if (t.timerRepeated_ == 0)
					{
						free(t.args_);
						t.args_ = nullptr;
					}
				}
			}
			else if (opt == ConType::ConType_db_client)
			{
				processDbServerMessage(t);
			}
			else if (opt == ConType::ConType_game_client)
			{	
				processMasterMessage(t);
			}
			else if (opt == ConType::ConType_cmd)
			{
				gScript.serverCmd(0, t.cmd_);
			}
			else if (opt == ConType::ConType_sql_gm)
			{
				std::string s(t.data_, t.len_);
				gScript.serverCmd(0, s);
			}
			else if (opt == ConType::ConType_one_per_time)
			{
				gScript.secondUpdate();
			}
			else if (opt == ConType::ConType_http_gm)
			{
				std::string s(t.data_, t.len_);
				gScript.processHttp(0, s);
			}			
			else if (opt == ConType::ConType_fight_res)
			{
				gScript.fightEnd(t.sessionId_, t.fightRes);
			}
			else if (opt == ConType::ConType_close)
			{
				onClose();
			}
			if (t.data_)
			{
				free(t.data_);
			}

			qt_.pop();
		}

	}
}

bool MainThread::cleanDb()
{
	if (gParseConfig.isMasterServer() || gParseConfig.isGameServer())
	{
		try
		{
			std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(gMysqlClient.getMysqlCon()->prepareStatement("delete from closeserver"));
			if (!ps)
			{
				logInfo("cleanDb ps err");
				return false;
			}
			ps->execute();
		}
		catch (sql::SQLException &e)
		{
			logInfo(e.what());
		}

		try
		{
			std::unique_ptr<sql::PreparedStatement> ps1 = std::unique_ptr<sql::PreparedStatement>(gMysqlClient.getMysqlCon()->prepareStatement("delete from gm"));
			if (!ps1)
			{
				logInfo("cleanDb ps1 err");
				return false;
			}
			ps1->execute();
		}
		catch (sql::SQLException &e)
		{
			logInfo(e.what());
			return false;
		}
	}

	return true;
}

void MainThread::checkHttpGm()
{
	if(!gParseConfig.isGameServer())
	{
		return;
	}

	auto con = gMysqlClient.getCmdMysqlCon();
	if(!con)
	{
		logInfo("checkHttpGm err");
		return;
	}
	try
	{
		con->setAutoCommit(false);

		std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("select * from httpgm for update"));

		if (!ps)
		{
			con->rollback();
			con->setAutoCommit(true);
			logInfo("checkHttpGm ps err");
			return;
		}

		std::unique_ptr<sql::ResultSet> rst = std::unique_ptr<sql::ResultSet>(ps->executeQuery());
		if (!rst)
		{
			con->rollback();
			con->setAutoCommit(true);
			logInfo("checkHttpGm rst err");
			return;
		}

	
		while (rst->next())
		{	
			uint64_t id = rst->getUInt64("id");
			std::string type = std::to_string(rst->getInt("type"));
			std::string cmd = std::move(rst->getString("cmd"));
			
			https_.emplace(id, std::vector<std::string>{type, cmd});
		}
	

		int lens = https_.size();
		int idx = 1;
		std::string sqlDelete = "delete from httpgm where id in (";
		for (auto& e:https_) 
		{
			sqlDelete += std::to_string(e.first);
			if(idx++ < lens)
			{
				sqlDelete+=",";
			}
			
		}
		sqlDelete += ")";  

		if(lens > 0)
		{
			std::unique_ptr<sql::PreparedStatement> psDelete = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement(sqlDelete));
			if (!psDelete)
			{
				https_.clear();
				con->rollback();
				con->setAutoCommit(true);
				logInfo("checkHttpGm ps err");
				return;
			}

			psDelete->executeUpdate();
			con->commit();
			con->setAutoCommit(true);			
		}
		else
		{
			con->rollback();
			con->setAutoCommit(true);			
		}


	}
	catch (sql::SQLException &e)
	{
		https_.clear();
		con->rollback();
		con->setAutoCommit(true);
		logInfo(e.what());
		return;
	}


	for(auto e: https_)
	{
		try
		{
			nlohmann::json js;
			std::vector<std::string>& v= e.second;
			js["type"] = v[0];
			js["cmd"] = nlohmann::json::parse(v[1]);

			//logInfo("%s", v[1].data());
			std::string s = js.dump();

			size_t lens = s.size();
			Task t;
			t.data_ = (char *)malloc(lens);
			t.len_ = lens;
			t.opt_ = ConType::ConType_http_gm;

			memcpy(t.data_, s.data(), lens);

			std::unique_lock<std::mutex> lk(gMutex);
			gQueue.emplace(std::move(t));
			lk.unlock();
		}
		catch(const std::exception& e)
		{
			logInfo(e.what());
		}

	}

	https_.clear();

	
}

void MainThread::checkGm()
{
	bool ok = false;
	std::string cmd = "";
	std::string args = "";

	auto con = gMysqlClient.getCmdMysqlCon();
	if(!con)
	{
		logInfo("checkGm err");
		return;
	}

	{
		try
		{
			con->setAutoCommit(false);
			std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("select * from gm"));
			if (!ps)
			{
				con->rollback();
				con->setAutoCommit(true);
				logInfo("checkGm ps err");
				return;
			}

			std::unique_ptr<sql::ResultSet> rst = std::unique_ptr<sql::ResultSet>(ps->executeQuery());
			if (!rst)
			{
				con->rollback();
				con->setAutoCommit(true);
				logInfo("checkGm rst err");
				return;
			}

			while (rst->next())
			{
				cmd = rst->getString("cmd");
				args = rst->getString("args");
				ok = true;
			}
			con->commit();
			con->setAutoCommit(true);
		}
		catch (sql::SQLException &e)
		{
			con->rollback();
			con->setAutoCommit(true);
			logInfo(e.what());
			return;
		}
	}


	if (ok)
	{
		con->setAutoCommit(false);
		std::unique_ptr<sql::PreparedStatement> ps1 = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("delete from gm"));
		if (!ps1)
		{
			con->rollback();
			con->setAutoCommit(true);
			logInfo("checkGm ps1 err");
			return;
		}
		ps1->execute();
		con->commit();

		con->setAutoCommit(true);

		std::regex pattern("\\d+");
		std::smatch matches;

		for (auto it = std::sregex_iterator(args.begin(), args.end(), pattern); it != std::sregex_iterator(); ++it)
		{
			cmd.append(" ");
			cmd.append(it->str());
		}

		size_t lens = cmd.size();
		Task t;
		t.data_ = (char *)malloc(lens);
		t.len_ = lens;
		t.opt_ = ConType::ConType_sql_gm;

		memcpy(t.data_, cmd.data(), lens);

		std::unique_lock<std::mutex> lk(gMutex);
		gQueue.emplace(std::move(t));
		lk.unlock();
	}

	
}

void MainThread::noticeCloseGateSever()
{
	TcpConnecter *con = nullptr;

	pthread_spin_lock(&gsp);
	for (auto it = gClients.begin(); it != gClients.end(); it++)
	{
		con = it->second;
		break;
	}
	pthread_spin_unlock(&gsp);

	if (con)
	{
		EventLoop* loop = TcpServer::randLoop();
		if(loop)
		{
			uint32_t dataLen = 2 + 8 + 1;
			uint32_t maxLen = dataLen + 4;
			uint8_t where = 1;
			uint64_t csessionId = 0;
			char *buf = (char *)malloc(maxLen);

			dataLen = htonl(dataLen);
			memcpy(buf, &dataLen, 4);

			memcpy(buf + 4, &where, 1);

			csessionId = htobe64(csessionId);
			memcpy(buf + 5, &csessionId, 8);

			uint16_t netMessageId = htons(CoseServer);
			memcpy(buf + 13, &netMessageId, 2);

			Task t;
			t.data_ = buf;
			t.len_ = maxLen;
			t.sessionId_ = con->getSessionId();

			loop->addMessage(t);
			loop->weakUp();
		}


	}
}

void MainThread::checkClose()
{

	bool ok = false;
	auto con = gMysqlClient.getCmdMysqlCon();
	if(!con)
	{
		logInfo("checkClose");
		return;
	}

	try
	{
		con->setAutoCommit(false);
		std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("select * from closeserver"));
		if (!ps)
		{
			con->rollback();
			con->setAutoCommit(true);
			logInfo("checkGm ps1 err");
			return;
		}

		std::unique_ptr<sql::ResultSet> rst = std::unique_ptr<sql::ResultSet>(ps->executeQuery());
		if (!rst)
		{
			con->rollback();
			con->setAutoCommit(true);
			logInfo("checkGm rst err");
			return;
		}
		else
		{
			while (rst->next())
			{
				ok = true;
			}
			con->commit();
			con->setAutoCommit(true);
		}

	}
	catch (sql::SQLException &e)
	{
		con->rollback();
		con->setAutoCommit(true);
		logInfo(e.what());
		return;
	}


	if (ok)
	{
		try
		{
			con->setAutoCommit(false);
			std::unique_ptr<sql::PreparedStatement> ps1 = std::unique_ptr<sql::PreparedStatement>(con->prepareStatement("delete from closeserver"));
			if (!ps1)
			{
				con->rollback();
				con->setAutoCommit(true);
				logInfo("checkGm ps1 err");
				return;
			}

			ps1->execute();

			con->commit();
			con->setAutoCommit(true);

			sqlt_ = true;

			Task t;
			t.opt_ = ConType::ConType_close;

			std::unique_lock<std::mutex> lk(gMutex);
			gQueue.emplace(std::move(t));
			lk.unlock();
			gCondVar.notify_one();

		}
		catch (sql::SQLException &e)
		{
			con->rollback();
			con->setAutoCommit(true);
			logInfo(e.what());
		}

	}

	
}

bool MainThread::isCppProcess(const char *dest, const char *src)
{
	if (strncmp(dest, src, 3) == 0)
	{
		return true;
	}
	return false;
}

void MainThread::sendMessage2GateClient(uint64_t sessionId, uint64_t csessionId, const char *name, std::unique_ptr<google::protobuf::Message> message, uint8_t where)
{
	auto messIt = gNameMapMessId.find(name);
	if (messIt == gNameMapMessId.end())
	{
		logInfo("no find messageid %s", name);
		return;
	}

	uint16_t messageId = messIt->second.messageId_;

	EventLoop *loop = TcpServer::getLoop(sessionId);
	if(loop)
	{
		size_t len = message->ByteSizeLong();
		uint32_t dataLen = len + 2 + 8 + 1;
		uint32_t maxLen = dataLen + 4;
		char *buf = (char *)malloc(maxLen);

		size_t netDataLen = htonl(dataLen);
		memcpy(buf, &netDataLen, 4);

		memcpy(buf + 4, &where, 1);

		uint64_t ncsessionId = htobe64(csessionId);// 客户端的session
		memcpy(buf + 5, &ncsessionId, 8);

		uint16_t netMessageId = htons(messageId);
		memcpy(buf + 13, &netMessageId, 2);


		message->SerializeToArray(buf + 15, len);
		logInfo("------------------------发消息给客户端 sess:%llu, messageId:%d where:%d len:%d dataLen:%d maxLen:%d", csessionId, messageId, where, len, dataLen, maxLen);

		Task t;
		t.data_ = buf;
		t.len_ = maxLen;
		t.sessionId_ = sessionId;

		loop->addMessage(t);
		loop->weakUp();
	}
	else
	{
		logInfo("sendMessage2GateClient no find session %lu", sessionId);
	}

}

void MainThread::sendMessage2GameClient(uint64_t sessionId, const char *name, std::unique_ptr<google::protobuf::Message> message, uint64_t pid)
{
	auto messIt = gNameMapMessId.find(name);
	if (messIt == gNameMapMessId.end())
	{
		logInfo("server(%s) sendMessage2GameClient no find messageid, name = %s", gParseConfig.name_.data(), name);
		return;
	}

	uint16_t messageId = messIt->second.messageId_;


	EventLoop *loop = tcp_.getLoop(sessionId);

	if(loop)
	{
		uint32_t len = (uint32_t)message->ByteSizeLong();
		uint32_t dataLen = len + 2 + 8;
		uint32_t maxLen = 4 + dataLen;

		uint32_t netDataLen = htonl(dataLen);
		uint16_t netMessId = htons(messageId);
		uint64_t netPid = htobe64(pid);

		char *buf = (char *)malloc(maxLen);

		memcpy(buf, &netDataLen, 4);
		memcpy(buf + 4, &netMessId, 2);
		memcpy(buf + 6, &netPid, 8);

		message->SerializeToArray(buf + 14, len);

		Task t;
		t.data_ = buf;
		t.len_ = maxLen;
		t.sessionId_ = sessionId;

		loop->addMessage(t);
		loop->weakUp();
	}
	else
	{
		logInfo("sendMessage2GameClient err");
	}

}

void MainThread::processDbServerMessage(Task &t)
{
	if (t.data_ && t.len_ > 0)
	{
		uint16_t messageId = 0;
		memcpy(&messageId, t.data_, 2);
		messageId = ntohs(messageId);

		//logInfo("processDbServerMessage %d", messageId);
		dispatchDbServerMessage(messageId, t.data_ + 2, t.len_ - 2);
	}
}



void MainThread::processMasterMessage(Task &t)
{
	//logInfo("processMasterMessageprocessMasterMessageprocessMasterMessage");
	if (t.connect_)
	{
		ReqGameReport req;
		req.set_serverid(gParseConfig.serverId_);
		sendMessage2MasterServer(req, (uint16_t)ProtoIdDef::ReqGameReport);
	}
	else if (t.data_ && t.len_ > 0)
	{
		uint16_t messageId = 0;
		memcpy(&messageId, t.data_, 2);
		messageId = ntohs(messageId);

		auto it = gMessIdMapName.find(messageId);
		if (it == gMessIdMapName.end())
		{
			logInfo("processMasterMessage no find name, messageId = %d", messageId);
		}
		else
		{
			const char *name = it->second.name_.data();
			uint64_t pid = 0;
			memcpy(&pid, t.data_ + 2, 8);
			pid = be64toh(pid);

			if (pid > 0) // 消息直接转发给前端
			{
				Player *player = gPlayerMgr.getPlayerById(pid);
				if (player)
				{
					const google::protobuf::Descriptor *desc = g_importer.pool()->FindMessageTypeByName(name);
					if (!desc)
					{
						logInfo("------------processMasterMessage no find desc, name:%s", name);
						return;
					}

					const google::protobuf::Message *mess = g_factory.GetPrototype(desc);
					if (!mess)
					{
						logInfo("------------processMasterMessage no find mess, name:%s", name);
						return;
					}
					std::unique_ptr<google::protobuf::Message> message(mess->New());
					(message.get())->ParseFromArray(t.data_ + 10, t.len_ - 10);
					sendMessage2GateClient(player->getSessionId(), player->getCsessionId(), name, std::move(message));
				}
			}
			else
			{
				if (isCppProcess(it->second.lang_.data(), "cpp"))
				{
					//dispatchMasterServerMessage(messageId, t.data_ + 10, t.len_ - 10);
				}
				else
				{
					gScript.onMessage(messageId, 0, name, t.data_ + 10, t.len_ - 10);
				}
			}
		}
	}
}

void MainThread::processLogicGameMessage(Task &t)
{
	//logInfo("processLogicGameMessageprocessLogicGameMessageprocessLogicGameMessage");
	if (t.close_)
	{
		uint64_t sessionId = t.sessionId_;
		uint16_t serverId = getLogicServerId(sessionId);
		logicId2Session_.erase(serverId);
		session2LogicId_.erase(sessionId);
		logInfo("------------------ serverid: %d dis connect", serverId);
	}
	else
	{
		if (t.data_ && t.len_ > 0)
		{
			uint16_t messageId = 0;
			memcpy(&messageId, t.data_, 2);
			messageId = ntohs(messageId);

			if (messageId == (uint16_t)ProtoIdDef::ReqGameReport)
			{
				ReqGameReport req;
				req.ParseFromArray(t.data_ + 2, t.len_ - 2);
				uint16_t serverId = req.serverid();
				uint64_t sessionId = t.sessionId_;
				uint64_t oldSessionId = getLogicSessionId(serverId);
				session2LogicId_.erase(oldSessionId);

				logicId2Session_.emplace(serverId, sessionId);
				session2LogicId_.emplace(sessionId, serverId);
				logInfo("------------------ serverid: %d report success", serverId);
			}
			else
			{
				auto it = gMessIdMapName.find(messageId);
				if (it == gMessIdMapName.end())
				{
					logInfo("processLogicGameMessage no find name, messageId = %d", messageId);
				}
				else
				{
					const char *name = it->second.name_.data();
					if (isCppProcess(it->second.lang_.data(), "cpp"))
					{
						dispatchGameClientMessage(messageId, t.sessionId_, t.data_ + 2, t.len_ - 2);
					}
					else
					{
						gScript.onMessage(messageId, t.sessionId_, name, t.data_ + 2, t.len_ - 2, true);
					}
				}
			}
		}
	}
}


void MainThread::processGateClientMessage(Task &t)
{
	if (t.close_)
	{	
		logInfo("网关进程意外关闭了");
		removeAllAccountData();
		gPlayerMgr.closeAllPlayer();

		return;

	}

	uint8_t status = 0;
	memcpy(&status, t.data_, 1);

	uint64_t csessionId = 0;
	memcpy(&csessionId, t.data_ + 1, 8);
	csessionId = be64toh(csessionId);


	if (status == 1)
	{
		logInfo("收到一个前端关闭连接的消息 %llu", csessionId);
		removeAccount(csessionId);
		Player *player = gPlayerMgr.getPlayer(csessionId);
		if (player)
		{
			uint64_t pid = player->getPid();

			gPlayerMgr.playerLogout(player);
			gPlayerMgr.cleanPlayerLuaModuleData(pid);
			gPlayerMgr.removePlayerById(pid);
			gPlayerMgr.removePlayerBySessionId(csessionId);
		}
	}
	else if (t.data_ && t.len_ > 0)
	{

		uint16_t messageId = 0;
		memcpy(&messageId, t.data_ + 9, 2);
		messageId = ntohs(messageId);

		//logInfo("收到前端业务消息 sess:%llu mess:%u", csessionId, messageId);

		auto it = gMessIdMapName.find(messageId);
		if (it == gMessIdMapName.end())
		{
			logInfo("no find name, protoid = %d", messageId);
		}
		else
		{
			if (isCppProcess(it->second.lang_.data(), "cpp"))
			{

				dispatchGateClientMessage(t.sessionId_, messageId, csessionId, t.data_ + 11, t.len_ - 11);
			}
			else
			{
				gScript.onMessage(messageId, csessionId, it->second.name_.data(), t.data_ + 11, t.len_ - 11, false, true);
			}
		}
	}
}

void MainThread::closeServer(uint8_t useDb)
{
	gTimer.closeTimer();

	if (!gParseConfig.daemon_ && (gParseConfig.isGameServer() || gParseConfig.isMasterServer()))
	{
		rl_cleanup_after_signal();
		cmdStopFlag = false;
	}

	gPlayerMgr.closeAllPlayer(useDb);

	LuaBind::CallLua cl(gScript.l, "gGetGlobalModuleData", 1);
	std::map<uint8_t, const char *> datas = cl.call<std::map<uint8_t, const char *>, void>();
	saveGlobalData(datas, useDb);
}

void MainThread::removeAllAccountData()
{
	for (auto it = accountData_.begin(); it != accountData_.end();)
	{
		Account &ac = it->second;
		accountList_.erase(createAccountKey(ac.account_, ac.pf_, gParseConfig.serverId_));
		it = accountData_.erase(it++);
	}
}

void MainThread::removeAccount(uint64_t sessionId)
{
	auto it = accountData_.find(sessionId);
	if (it == accountData_.end())
	{
		return;
	}

	Account &ac = it->second;
	accountList_.erase(createAccountKey(ac.account_, ac.pf_, gParseConfig.serverId_));
	accountData_.erase(it);
}

void MainThread::removeAccountByAccount(std::string account, std::string pf, int serverId)
{
	std::string key = createAccountKey(account, pf, serverId);
	auto it = accountList_.find(key);
	if (it != accountList_.end())
	{
		uint64_t sessionId = it->second;
		auto it1 = accountData_.find(sessionId);
		if (it1 != accountData_.end())
		{
			accountData_.erase(it1);
		}

		accountList_.erase(it);
		logInfo("----------------------移除账号成功");
	}



}

uint64_t MainThread::accountIsOnline(const std::string &key)
{
	auto it = accountList_.find(key);
	if (it == accountList_.end())
	{
		return 0;
	}
	return it->second;
}



Account *MainThread::getAccount(uint64_t sessionId)
{
	auto it = accountData_.find(sessionId);
	if (it == accountData_.end())
	{
		return 0;
	}
	return &it->second;
}

void MainThread::forceCloseSession(uint64_t sessionId, uint64_t csessionId, uint8_t reaon)
{
	removeAccount(csessionId);
	Player *player = gPlayerMgr.getPlayer(csessionId);
	if (player)
	{
		uint64_t pid = player->getPid();
		gPlayerMgr.playerLogout(player);
		gPlayerMgr.cleanPlayerLuaModuleData(pid);
		gPlayerMgr.removePlayerById(pid);
		gPlayerMgr.removePlayerBySessionId(csessionId);
	}

	logInfo("服务器主动关闭客户端连接 %llu reason:%d", csessionId, reaon);

	std::unique_ptr<NotifyServerCloseClient>res(std::make_unique<NotifyServerCloseClient>());
	res->set_code(reaon);
	sendMessage2GateClient(sessionId, csessionId, "NotifyServerCloseClient", std::move(res));

}



void MainThread::addMailLog(Player *player, const char *mail)
{
	// try
	// {
	// 	nlohmann::json js = nlohmann::json::parse(mail);
	// 	WriteMailData wd;
	// 	wd.set_pid(player->getPid());
	// 	wd.set_account(player->getAccount());
	// 	wd.set_pf(player->getPf());
	// 	wd.set_name(player->getName());
	// 	wd.set_serverid(gParseConfig.serverId_);

	// 	auto data = wd.add_data();
	// 	data->set_mailid(js["mailId"]);
	// 	data->set_desc(js["desc"]);

	// 	nlohmann::json rd = js["reward"];
	// 	std::string s = rd.dump();
	// 	data->set_reward(s);
	// 	nlohmann::json extra = js["extra"];
	// 	std::string sextra = extra.dump();
	// 	data->set_extra(sextra);
	// 	data->set_title(js["title"]);
	// 	data->set_content(js["content"]);
	// 	data->set_expiretime(js["expireTime"]);

	// 	sendMessage2LogServer(wd, 2);
	// }
	// catch (const std::exception &e)
	// {
	// 	logInfo(e.what());
	// }
}

void MainThread::sendMessage2Master(uint32_t masterId, const char *name, std::unique_ptr<google::protobuf::Message> message, uint64_t placeholder)
{
	auto messIt = gNameMapMessId.find(name);
	if (messIt == gNameMapMessId.end())
	{
		logInfo("sendMessage2MasterByLua no find data, name = %s", name);
		return;
	}

	sendMessage2MasterServer(*message, messIt->second.messageId_);
}



bool MainThread::loadGlobalData()
{
	uint16_t serverId = gParseConfig.serverId_;
	
	try
	{
		std::unique_ptr<sql::PreparedStatement> ps = std::unique_ptr<sql::PreparedStatement>(gMysqlClient.getMysqlCon()->prepareStatement("select data, moduleid from globaldata where serverid=?"));
		if (!ps)
		{
			logInfo("loadGlobalData ps err");
			return false;
		}

		ps->setInt(1, serverId);
		std::unique_ptr<sql::ResultSet> rst = std::unique_ptr<sql::ResultSet>(ps->executeQuery());
		if (!rst)
		{
			logInfo("loadGlobalData rst err");
			return false;
		}

		while (rst->next())
		{
			const std::string s = rst->getString("data");
			int moduleId = rst->getInt("moduleid");
			LuaBind::CallLua cl(gScript.l, "gLoadGlobalModuleData");
			cl.call<void, void>(moduleId, s);
		}
	}
	catch (sql::SQLException &e)
	{
		logInfo(e.what());
		return false;
	}

	return true;
}

void MainThread::saveGlobalData(std::map<uint8_t, const char *> datas, uint8_t useDb)
{
	uint16_t serverId = gParseConfig.serverId_;
	for (auto &e : datas)
	{
		if(useDb == 1)
		{
			__saveGlobalData(e.first, e.second, serverId);
		}
		else
		{
			ReqSaveGlobalData req;
			req.set_moduleid(e.first);
			req.set_serverid(serverId);
			req.set_data(e.second);

			sendMessage2DbServer(req, (uint16_t)ProtoIdDef::ReqSaveGlobalData);
		}
	}
}



uint16_t MainThread::getLogicServerId(uint64_t sessionId)
{
	auto it = session2LogicId_.find(sessionId);
	if (it == session2LogicId_.end())
	{
		return 0;
	}
	return it->second;
}

uint64_t MainThread::getLogicSessionId(uint16_t serverId)
{
	auto it = logicId2Session_.find(serverId);
	if (it == logicId2Session_.end())
	{
		return 0;
	}
	return it->second;
}

std::unordered_map<uint64_t, uint16_t> MainThread::getLogicServerList()
{
	return session2LogicId_;
}

bool MainThread::isValidStr(const char *str)
{
	std::wstring text = gTools.changeStr(str);
	if (text.length() == 0)
	{
		return false;
	}

	LuaBind::CallLua cl(gScript.l, "gGetAllowWord", 1);
	std::map<uint32_t, uint32_t> allow = cl.call<std::map<uint32_t, uint32_t>, void>();
	for (wchar_t &c : text)
	{
		if (!isAllowCharacter(c, allow) && !std::iswalpha(c))
		{
			return false;
		}
	}

	return true;
}

bool MainThread::isAllowCharacter(wchar_t c, std::map<uint32_t, uint32_t> &allow)
{
	for (auto e : allow)
	{
		if (c >= (wchar_t)e.first && c <= (wchar_t)e.second)
		{
			return true;
		}
	}
	return false;
}

bool MainThread::checkPortUsed()
{
    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) 
	{
		logInfo("checkPortUsed socket err");
        return false;
    }

    int opt = 1;
    if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0) 
	{
		logInfo("checkPortUsed setsockopt err");
        close(sockfd);
        return false;
    }


    struct sockaddr_in address;
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY; 
    address.sin_port = htons(gParseConfig.dbPort_); 

    // 尝试绑定到指定端口
    if (bind(sockfd, (struct sockaddr *)&address, sizeof(address)) < 0) 
	{
        close(sockfd);
        return true;
    }

    close(sockfd);
    return false;
}

void MainThread::onClose()
{

	logInfo("开始关闭游戏服务器");

	if(gParseConfig.isGameServer())
	{
		gMainThread.noticeCloseGateSever();
	}

	ReqGameQuit req;
	gMainThread.sendMessage2DbServer(req, (uint16_t)ProtoIdDef::ReqCloseDbServer);
	
	if (gParseConfig.isGameServer())
	{
		for (auto &e : gServerClients)
		{
			e.second->quit_ = true;
		}
	}	

	if (gParseConfig.isGameServer())
	{
		for (auto &e : gServerClients)
		{
			e.second->quitClient();
		}
	}	


	while (1)
	{
		if(checkPortUsed())
		{
			logInfo("等待db退出中...");
			sleep(1);
			continue;
		}
		else
		{
			break;
		}
	}


	gRankMgr.saveRankData(1);
	gMainThread.closeServer(1);

	tcp_.quitIoLoop();
	logInfo("数据保存完毕...");


	quit_ = true;


	std::unique_lock<std::mutex> lk(gMutex);
	Task t;
	gQueue.emplace(std::move(t));
	lk.unlock();
	gCondVar.notify_one();
}

void MainThread::save()
{
	onClose();
}

bool MainThread::checkNetworkConnection(const char* str)
{
    struct sockaddr_in serv_addr;
    struct hostent *server;

    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) 
	{
		logInfo("checkNetworkConnection err1");
        return false;
    }

    server = gethostbyname(str);
    if (server == NULL) 
	{
		logInfo("checkNetworkConnection err2");
        return false;
    }

    bzero((char *) &serv_addr, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    bcopy((char *)server->h_addr, (char *)&serv_addr.sin_addr.s_addr, server->h_length);
    serv_addr.sin_port = htons(80);

    if (connect(sockfd,(struct sockaddr *) &serv_addr,sizeof(serv_addr)) < 0) 
	{
		logInfo("checkNetworkConnection no connect %s %d", str, errno);
        return false;
    }

    close(sockfd);
    return true;
}

int MainThread::getMessageCnt()
{
	int cnt = 0;
	std::unique_lock<std::mutex> lk(gMutex);
	cnt = (int)gQueue.size();
	lk.unlock();
	return cnt;
}


void MainThread::sendMessage2Http(const char* host, const char* path, std::string data)
{
	//const char * host = "gm-zhujiange.scszsj.com";
	// const char* path = "/log_login?";

    char buf[1024]={0};
	int dataLen = (int)data.length();
    // 格式化字符串
    snprintf(buf, 1024,
             "POST %s HTTP/1.1\r\n"
             "Host: %s\r\n"
             "Content-Type: application/x-www-form-urlencoded\r\n"
             "Content-Length: %d\r\n"
             "Connection: keep-alive\r\n\r\n"
             "%s",
             path, host, dataLen, data.c_str());
    
	int len = strlen(buf);
	Task tk;
	char* p = (char*)malloc(len);
	memcpy(p, buf, len);
	tk.data_ = p;
	tk.len_ = len;		
	tcp_.sendMessage2HttpServer(tk);
}

