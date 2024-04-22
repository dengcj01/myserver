

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
#include "../../../libs/jemalloc/jemalloc.h"
#include "msgHandle/msgHandle.h"
#include "script/Script.h"
#include "../../common/MysqlClient.h"
#include "../../../libs/mysql/mysql_connection.h"
#include "../../../libs/mysql/mysql_error.h"
#include "../../../libs/mysql/cppconn/resultset.h"
#include "../../../libs/mysql/cppconn/statement.h"
#include "../../../libs/mysql/cppconn/prepared_statement.h"
#include "../../common/pb/ServerCommon.pb.h"
#include "../../common/ParseConfig.hpp"
#include "../../common/Rank.hpp"
#include "../../../libs/google/protobuf/dynamic_message.h"
#include "../../../libs/google/protobuf/compiler/importer.h"
#include "pb/Login.pb.h"

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

void MainThread::cacheCppProto()
{
	if (gParseConfig.isGameServer())
	{
		LuaBind::CallLua cl(gScript.l, "gGetCppProto");
		std::map<uint16_t, const char *> data = cl.call<std::map<uint16_t, const char *>, void>();
		for (auto &e : data)
		{
			uint16_t id = e.first;
			const char *name = e.second;
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
			if (strcmp(name, "ReqBagData") == 0)
			{
				cppProto_[id] = reqBagData;
			}
		}
	}
}

void MainThread::start(uint16_t port)
{
	cacheCppProto();
	cleanDb();
	sqlThread_ = std::move(std::thread([&]()
									   {
			while (true){
				checkGm();
				checkClose();

				if(sqlt_.load(std::memory_order_relaxed))
				{
					break;
				}
				sleep(1);
		} }));
	sqlThread_.detach();

	{

		uint8_t mod = ConType::conType_game_server;

		if (gParseConfig.isMasterServer())
		{
			mod = ConType::ConType_master_server;
		}
		else
		{
			initClient();
		}

		bool cmd = !gParseConfig.daemon_ && (gParseConfig.isGameServer() || gParseConfig.isMasterServer());

		tcp_.start(port, mod, cmd);

		LuaBind::CallLua cl(gScript.l, "gServerStart");
		cl.call<void, void>();
	}

	logInfo("-------------------start %s server success ------------------------", gParseConfig.name_.data());
	while (isRunning_)
	{
		std::unique_lock<std::mutex> lk(gMutex);
		while (gQueue.empty())
		{
			gCondVar.wait(lk);
		}

		while (!gQueue.empty())
		{
			qt_.push(std::move(gQueue.front()));
			gQueue.pop();
		}

		lk.unlock();

		if (quit_.load(std::memory_order_relaxed))
		{
			logQuit("------------------------quit  game  success------------");
			break;
		}

		//logInfo("-----------------------%d", qt_.size());
		while (!qt_.empty())
		{
			Task &t = qt_.front();
			uint8_t opt = t.opt_;
			if (opt == ConType::conType_game_server)
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
						je_free(t.args_);
					}
				}
				else
				{
					gScript.callLuaTimer(t.args_->pid_, t.args_->luaFunc_, t.args_->tid_, t.timerRepeated_);
					if (t.timerRepeated_ == 0)
					{
						je_free(t.args_);
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
			else if (t.cmd_.size() > 0)
			{
				gScript.serverCmd(0, t.cmd_);
			}
			else if (opt == ConType::ConType_sql_gm)
			{
				std::string s(t.data_, t.len_);
				gScript.serverCmd(0, s);
			}
			else if (opt == 0)
			{
				gScript.secondUpdate();
			}
			else if (opt == ConType::ConType_fight_res)
			{
				gScript.fightEnd(t.sessionId_, t.fightRes);
			}
			else if (opt == ConType::ConType_gamecenter_client)
			{

			}
			if (t.data_)
			{
				je_free(t.data_);
			}

			qt_.pop();
		}
	}
}

void MainThread::cleanDb()
{
	if (gParseConfig.isMasterServer() || gParseConfig.isGameServer())
	{
		sql::PreparedStatement *ps = 0;
		try
		{
			ps = gMysqlClient.getMysqlCon()->prepareStatement("delete from closeserver");
			ps->execute();
			delete ps;
		}
		catch (sql::SQLException &e)
		{
			logInfo(e.what());
		}

		try
		{
			ps = gMysqlClient.getMysqlCon()->prepareStatement("delete from gm");
			ps->execute();
			delete ps;
		}
		catch (sql::SQLException &e)
		{
			logInfo(e.what());
		}
	}
}

void MainThread::checkGm()
{
	bool ok = false;
	std::string cmd = "";
	std::string args = "";
	sql::PreparedStatement *ps = nullptr;
	try
	{
		gMysqlClient.getMysqlCon()->setAutoCommit(false);
		ps = gMysqlClient.getMysqlCon()->prepareStatement("select * from gm");
		sql::ResultSet *rst = ps->executeQuery();

		while (rst->next())
		{
			cmd = rst->getString("cmd");
			args = rst->getString("args");
			ok = true;
		}
		gMysqlClient.getMysqlCon()->commit();
		gMysqlClient.getMysqlCon()->setAutoCommit(true);


		delete rst;
		delete ps;
	}
	catch (sql::SQLException &e)
	{
		logInfo(e.what());
	}

	if (ok)
	{

		ps = gMysqlClient.getMysqlCon()->prepareStatement("delete from gm");
		ps->execute();
		delete ps;

		std::regex pattern("\\d+");
		std::smatch matches;

		for (auto it = std::sregex_iterator(args.begin(), args.end(), pattern); it != std::sregex_iterator(); ++it)
		{
			cmd.append(" ");
			cmd.append(it->str());
		}

		size_t lens = cmd.size();
		Task t;
		t.data_ = (char *)je_malloc(lens);
		t.len_ = lens;
		t.opt_ = ConType::ConType_sql_gm;
		memcpy(t.data_, cmd.data(), lens);
		std::unique_lock<std::mutex> lk(gMutex);
		gQueue.emplace(std::move(t));
		lk.unlock();
	}
}

void MainThread::noticeCloseGate()
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
		EventLoop *loop = con->getEventLoop();

		uint32_t dataLen = 2 + 8 + 1;
		uint32_t maxLen = dataLen + 4;
		uint8_t where = 1;
		uint64_t csessionId = 0;
		uint16_t messageId = 0;
		char *buf = (char *)je_malloc(maxLen);

		memcpy(buf, &dataLen, 4);
		memcpy(buf + 4, &where, 1);
		memcpy(buf + 5, &csessionId, 8);
		memcpy(buf + 13, &messageId, 2);

		Task t;
		t.data_ = buf;
		t.len_ = maxLen;
		t.sessionId_ = con->getSessionId();

		loop->addMessage(t);
		loop->weakUp();
	}
}

void MainThread::checkClose()
{
	Task t;
	t.opt_ = 0;
	gQueue.emplace(std::move(t));
	gCondVar.notify_one();

	bool ok = false;
	sql::PreparedStatement *ps = nullptr;
	try
	{
		gMysqlClient.getMysqlCon()->setAutoCommit(false);
		ps = gMysqlClient.getMysqlCon()->prepareStatement("select * from closeserver");
		sql::ResultSet *rst = ps->executeQuery();

		while (rst->next())
		{
			ok = true;
		}
		gMysqlClient.getMysqlCon()->commit();
		gMysqlClient.getMysqlCon()->setAutoCommit(true);
		delete rst;
		delete ps;
	}
	catch (sql::SQLException &e)
	{
		logInfo(e.what());
	}

	if (ok)
	{
		ReqGameQuit req;
		gMainThread.sendMessage2DbServer(req, 255);
		gMainThread.sendMessage2LogServer(req, 255);
		if (gParseConfig.isGameServer())
		{
			gMainThread.noticeCloseGate();
		}

		sleep(1);

		sqlt_.store(true, std::memory_order_relaxed);

		ps = gMysqlClient.getMysqlCon()->prepareStatement("delete from closeserver");
		ps->execute();
		delete ps;

		gRankMgr.saveRankData();
		gMainThread.closeServer();
		gMainThread.sendMessage2DbServer(req, 255);
		sleep(1);
		if (gParseConfig.isGameServer())
		{
			for (auto &e : gServerClients)
			{
				e.second->quit_ = true;
				sleep(1);
			}

			for (auto &e : gServerClients)
			{
				e.second->quitClient();
			}

			sleep(2);
		}

		gMainThread.quit_.store(true, std::memory_order_relaxed);

		Task t;
		t.opt_ = 0;
		gQueue.emplace(std::move(t));
		gCondVar.notify_one();
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

	int messageId = messIt->second.messageId_;
	TcpConnecter *con = nullptr;

	pthread_spin_lock(&gsp);
	auto it = gClients.find(sessionId);
	if (it == gClients.end())
	{
		logInfo("no find sessionid %s", name);
		pthread_spin_unlock(&gsp);
		return;
	}
	con = it->second;
	pthread_spin_unlock(&gsp);

	EventLoop *loop = con->getEventLoop();

	size_t len = message->ByteSizeLong();
	uint32_t dataLen = len + 2 + 8 + 1;
	uint32_t maxLen = dataLen + 4;
	char *buf = (char *)je_malloc(maxLen);

	memcpy(buf, &dataLen, 4);
	memcpy(buf + 4, &where, 1);
	memcpy(buf + 5, &csessionId, 8);
	memcpy(buf + 13, &messageId, 2);
	message->SerializeToArray(buf + 15, len);

	Task t;
	t.data_ = buf;
	t.len_ = maxLen;
	t.sessionId_ = sessionId;

	loop->addMessage(t);
	loop->weakUp();
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
	TcpConnecter *con = nullptr;
	pthread_spin_lock(&gsp);
	auto it = gClients.find(sessionId);
	if (it == gClients.end())
	{
		logInfo("sendMessage2GameClient err, no find messageId = %llu", sessionId);
		pthread_spin_unlock(&gsp);
		return;
	}

	con = it->second;
	pthread_spin_unlock(&gsp);

	EventLoop *loop = con->getEventLoop();
	uint32_t len = (uint32_t)message->ByteSizeLong();
	uint32_t dataLen = len + 2 + 8;
	uint32_t maxLen = 4 + dataLen;

	char *buf = (char *)je_malloc(maxLen);
	memcpy(buf, &dataLen, 4);
	memcpy(buf + 4, &messageId, 2);
	memcpy(buf + 6, &pid, 8);
	message->SerializeToArray(buf + 14, len);

	Task t;
	t.data_ = buf;
	t.len_ = maxLen;
	t.sessionId_ = sessionId;

	loop->addMessage(t);
	loop->weakUp();
}

void MainThread::processDbServerMessage(Task &t)
{
	if (t.data_ && t.len_ > 0)
	{
		uint16_t messageId = 0;
		memcpy(&messageId, t.data_, 2);
		dispatchDbServerMessage(messageId, t.data_ + 2, t.len_ - 2);
	}
}

void MainThread::processCenterMessage(Task &t)
{
	if (t.data_ && t.len_ > 0)
	{
		uint16_t messageId = 0;
		memcpy(&messageId, t.data_, 2);

		if (messageId == g2mReqGameReport)
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
				}
				else
				{
					gScript.onMessage(messageId, t.sessionId_, name, t.data_ + 2, t.len_ - 2, true);
				}
			}
		}
	}
}

void MainThread::processMasterMessage(Task &t)
{
	if (t.connect_)
	{
		ReqGameReport req;
		req.set_serverid(gParseConfig.serverId_);
		sendMessage2MasterServer(req, g2mReqGameReport);
	}
	else if (t.data_ && t.len_ > 0)
	{
		uint16_t messageId = 0;
		memcpy(&messageId, t.data_, 2);

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

			if (pid > 0)
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

			if (messageId == g2mReqGameReport)
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
		logInfo("client allobj close");
		enter_.clear();
		removeAllAccountData();
		gPlayerMgr.closeAllPlayer();
		return;
	}

	uint8_t status = 0;
	memcpy(&status, t.data_, 1);

	uint64_t csessionId = 0;
	memcpy(&csessionId, t.data_ + 1, 8);

	if (status == 1)
	{

		removeAccount(csessionId);
		Player *player = gPlayerMgr.getPlayer(csessionId);
		if (player)
		{
			uint64_t pid = player->getPid();
			//logInfo("client close %llu", pid);

			gPlayerMgr.playerLogout(player);
			gPlayerMgr.cleanPlayerLuaModuleData(pid);
		}
	}
	else if (t.data_ && t.len_ > 0)
	{
		uint16_t messageId = 0;
		memcpy(&messageId, t.data_ + 9, 2);

		auto it = gMessIdMapName.find(messageId);
		if (it == gMessIdMapName.end())
		{
			logInfo("no find name, messageId = %d", messageId);
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

void MainThread::closeServer()
{
	gTimer.closeTimer();
	tcp_.quitIoLoop();
	if (!gParseConfig.daemon_ && (gParseConfig.isGameServer() || gParseConfig.isMasterServer()))
	{
		tcp_.cmdQuit_.store(true, std::memory_order_relaxed);
	}

	gPlayerMgr.closeAllPlayer();
	saveGlobalData();
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

uint64_t MainThread::accountIsOnline(const std::string &key)
{
	auto it = accountList_.find(key);
	if (it == accountList_.end())
	{
		return 0;
	}
	return it->second;
}



void MainThread::initClient()
{
	if (gParseConfig.isGameServer())
	{
		for (uint8_t i = ConType::ConType_db_client; i <= ConType::ConType_log_client; i++)
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
			else if (i == ConType::ConType_log_client)
			{
				cli->init(i, gParseConfig.logPort_, gParseConfig.logIp_.data());
			}
		}
		//cli->init(ConType_gamecenter_client, gParseConfig.centerPort, gParseConfig.centerIp_.data());
	}
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
		gPlayerMgr.playerLogout(player);
		gPlayerMgr.cleanPlayerLuaModuleData(player->getPid());
	}

	logInfo("forceCloseSession %d", reaon);
	std::unique_ptr<ResServerCloseClient>
	res(std::make_unique<ResServerCloseClient>());
	sendMessage2GateClient(sessionId, csessionId, "ResServerCloseClient", std::move(res), reaon);
}

void MainThread::forceCloseAllSession()
{
	tcp_.forceCloseAllSession();
}

void MainThread::addMailLog(Player *player, const char *mail)
{
	try
	{
		nlohmann::json js = nlohmann::json::parse(mail);
		WriteMailData wd;
		wd.set_pid(player->getPid());
		wd.set_account(player->getAccount());
		wd.set_pf(player->getPf());
		wd.set_name(player->getName());
		wd.set_serverid(gParseConfig.serverId_);

		auto data = wd.add_data();
		data->set_mailid(js["mailId"]);
		data->set_desc(js["desc"]);

		nlohmann::json rd = js["reward"];
		std::string s = rd.dump();
		data->set_reward(s);
		nlohmann::json extra = js["extra"];
		std::string sextra = extra.dump();
		data->set_extra(sextra);
		data->set_title(js["title"]);
		data->set_content(js["content"]);
		data->set_expiretime(js["expireTime"]);

		sendMessage2LogServer(wd, 2);
	}
	catch (const std::exception &e)
	{
		logInfo(e.what());
	}
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

void MainThread::initNames(std::string &path)
{
	std::vector<std::string> used;
	try
	{
		sql::PreparedStatement *ps = gMysqlClient.getMysqlCon()->prepareStatement("select * from usedname");
		sql::ResultSet *rst = ps->executeQuery();

		while (rst->next())
		{
			used.emplace_back(rst->getString("name").asStdString());
		}
		delete rst;
		delete ps;
	}
	catch (sql::SQLException &e)
	{
		logInfo(e.what());
	}
	loadName(path, used, 1);
	loadName(path, used, 2);
}

void MainThread::loadName(std::string &path, std::vector<std::string> &used, uint8_t sex)
{
	std::string tmp = path;
	std::string tmpPath = tmp.append("logic/config/rand_names_1.lua");
	if (sex == 2)
	{
		tmpPath = tmp.append("logic/config/rand_names_2.lua");
	}

	std::ifstream file(tmpPath, std::ios::in);
	std::string line;

	std::unordered_map<std::string, uint8_t> datas;
	uint32_t cnt = 0;
	if (file.is_open())
	{
		while (std::getline(file, line))
		{
			if (line[line.size() - 1] == '\r')
			{
				line.erase(line.size() - 1);
			}
			datas.emplace(line, 1);
			cnt += 1;
		}
		file.close();
	}

	for (auto &e : used)
	{
		auto it = datas.find(e);
		if (it != datas.end())
		{
			datas.erase(it);
		}
	}

	if (sex == 1)
	{
		manNames_.reserve(cnt);
		for (auto &e : datas)
		{
			manNames_.emplace_back(e.first);
		}
		manNames_.shrink_to_fit();
	}
	else
	{
		womanNames_.reserve(cnt);
		for (auto &e : datas)
		{
			womanNames_.emplace_back(e.first);
		}
		womanNames_.shrink_to_fit();
	}
}

const std::string MainThread::randName(uint8_t sex)
{
	if (sex == 1)
	{
		size_t lens = manNames_.size();
		if (lens > 0)
		{
			std::string name = manNames_[lens - 1];
			manNames_.pop_back();
			manNames_.shrink_to_fit();
			return name;
		}
		return "";
	}

	size_t lens = womanNames_.size();
	if (lens > 0)
	{
		std::string name = womanNames_[lens - 1];
		womanNames_.pop_back();
		womanNames_.shrink_to_fit();
		return name;
	}
	return "";
}

void MainThread::loadGlobalData()
{
	uint16_t serverId = gParseConfig.serverId_;

	sql::PreparedStatement *ps = nullptr;
	try
	{
		ps = gMysqlClient.getMysqlCon()->prepareStatement("select data, moduleid from globaldata where serverid=?");
		ps->setInt(1, serverId);
		sql::ResultSet *rst = ps->executeQuery();

		while (rst->next())
		{
			LuaBind::CallLua cl(gScript.l, "gLoadGlobalModuleData");
			cl.call<void, void>(rst->getInt("moduleid"), rst->getString("data").asStdString());
		}
		delete rst;
		delete ps;
	}
	catch (sql::SQLException &e)
	{
		logInfo(e.what());
	}
}

void MainThread::saveGlobalData(bool timeFlag)
{
	uint16_t serverId = gParseConfig.serverId_;
	sql::PreparedStatement *ps = nullptr;
	const char *name = "gGetGlobalModuleData";
	if (timeFlag)
	{
		name = "gTimerGetGlobalModuleData";
	}

	LuaBind::CallLua cl(gScript.l, name);
	std::map<uint8_t, const char *> datas = cl.call<std::map<uint8_t, const char *>, void>();
	for (auto &e : datas)
	{
		try
		{
			ps = gMysqlClient.getMysqlCon()->prepareStatement("replace into globaldata(moduleid,serverid,data)values(?,?,?)");
			ps->setInt(1, e.first);
			ps->setInt(2, serverId);
			ps->setString(3, e.second);
			ps->execute();
			delete ps;
		}
		catch (sql::SQLException &e)
		{
			logInfo(e.what());
		}
	}
}

bool MainThread::isInEnter(uint64_t pid)
{
	auto it = enter_.find(pid);
	if (it == enter_.end())
	{
		return false;
	}

	Account *ac = getAccount(it->second);
	if (!ac)
	{
		return false;
	}

	return ac->status_;
}

void MainThread::resetEnter(uint64_t pid)
{
	auto it = enter_.find(pid);
	if (it == enter_.end())
	{
		return;
	}
	uint64_t sessionId = it->second;
	enter_.erase(it);

	Account *ac = getAccount(sessionId);
	if (!ac)
	{
		return;
	}
	ac->status_ = false;
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

	LuaBind::CallLua cl(gScript.l, "gGetAllowWord");
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

bool MainThread::isAllowCharacter(wchar_t c, std::map<uint32_t, uint32_t>& allow)
{
	for(auto e:allow)
	{
		if (c >= (wchar_t)e.first && c <= (wchar_t)e.second)
		{
			return true;
		}
	}
	return false;
}
