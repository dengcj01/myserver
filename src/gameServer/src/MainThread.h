#pragma once

#include <thread>
#include <mutex>
#include <unistd.h>
#include <condition_variable>
#include <queue>
#include <string>
#include <unordered_map>
#include "public/Lua.hpp"
#include "../../common/Singleton.h"
#include "../../../libs/jemalloc/jemalloc.h"
#include "../../common/net/TcpServer.h"
#include "../../common/net/Data.h"
#include "../../common/net/EventLoop.h"
#include "../../common/pb/ServerCommon.pb.h"

class Player;
class TcpServer;
class TcpConnecter;

struct MessageBaseInfo
{
	MessageBaseInfo(uint16_t messageId, const char *lang, const char *name) : messageId_(messageId),
																			  lang_(lang),
																			  name_(name)
	{
	}

	uint16_t messageId_;
	std::string lang_;
	std::string name_;
};

struct Account
{
	Account(const std::string &account, const std::string &pf, uint16_t fromServerId, uint64_t sessionId, uint64_t csessionId) : account_(account),
																						pf_(pf),
																						fromServerId_(fromServerId),
																						sessionId_(sessionId),
																						csessionId_(csessionId),
																						status_(false)
	{
	}

	std::string account_;
	std::string pf_;
	uint16_t fromServerId_;
	uint64_t sessionId_;
	uint64_t csessionId_;
	bool status_; // 是否给db发送了进入游戏协议(伪登入使用)
};

class MainThread : public Singleton<MainThread>
{
public:
	typedef void (*FunctionPtr)(uint64_t, uint64_t, char *, size_t);
	~MainThread();
	void start(uint16_t port);
	bool isValidStr(const char *str);
	bool isAllowCharacter(wchar_t c, std::map<uint32_t, uint32_t> &allow);
	bool isCppProcess(const char *dest, const char *src);
	void parseProto(const char *protoName);


	void sendMessage2GameClient(uint64_t sessionId, const char *name, std::unique_ptr<google::protobuf::Message> message, uint64_t pid = 0);
	void sendMessage2GateClient(uint64_t sessionId, uint64_t csessionId, const char *name, std::unique_ptr<google::protobuf::Message> message, uint8_t where = 0);
	void sendMessage2Master(uint32_t masterId, const char *name, std::unique_ptr<google::protobuf::Message> message, uint64_t placeholder = 0);

	Account *getAccount(uint64_t sessionId);
	void removeAccount(uint64_t sessionId);
	void cacheMessage(uint16_t messageId, const char *lang, const char *name, const char *desc);
	void closeServer();
	void initClient();
	void forceCloseSession(uint64_t sessionId, uint64_t csessionId, uint8_t reason);
	void forceCloseAllSession();
	uint64_t accountIsOnline(const std::string &key);

	void addMailLog(Player *player, const char *mail);
	void cleanDb();
	void loadGlobalData();
	void saveGlobalData(bool timeFlag = false);
	const std::string createAccountKey(const std::string &account, const std::string &pf, uint16_t fromServerId)
	{
		return account + pf + std::to_string(fromServerId);
	}

	void initNames(std::string &path);
	void loadName(std::string &path, std::vector<std::string> &used, uint8_t sex);
	const std::string randName(uint8_t sex);
	bool isInEnter(uint64_t pid);
	void resetEnter(uint64_t pid);
	void checkGm();
	void checkClose();
	void removeAllAccountData();
	void noticeCloseGate();
	FunctionPtr getProtoFunc(uint16_t messageId);
	void cacheCppProto();
	uint16_t getLogicServerId(uint64_t sessionId);
	uint64_t getLogicSessionId(uint16_t serverId);
	std::unordered_map<uint64_t, uint16_t> getLogicServerList();


	template <typename T>
	void packMessage(T &t, uint16_t messageId, Task &tk)
	{
		/* 协议格式
		包头----消息id----数据
		*/
		uint32_t len = t.ByteSizeLong();
		uint32_t dataLen = len + 2;
		uint32_t maxLen = 4 + dataLen;

		char *buf = (char *)je_malloc(maxLen);
		memcpy(buf, &dataLen, 4);
		memcpy(buf + 4, &messageId, 2);
		t.SerializeToArray(buf + 6, len);

		tk.data_ = buf;
		tk.len_ = maxLen;
		//logInfo("packMessage %d", maxLen);
	}

	template <typename T>
	void sendMessage2DbServer(T &t, uint16_t messageId)
	{
		Task tk;
		packMessage(t, messageId, tk);
		tcp_.sendMessage2DbServer(tk);
	}

	template <typename T>
	void sendMessage2LogServer(T &t, uint16_t messageId)
	{
		Task tk;
		packMessage(t, messageId, tk);
		tcp_.sendMessage2LogServer(tk);
	}

	template <typename T>
	void sendMessage2MasterServer(T &t, uint16_t messageId)
	{
		Task tk;
		packMessage(t, messageId, tk);
		tcp_.sendMessage2MasterServer(tk);
	}



private:
	void processGateClientMessage(Task &t);
	void processLogicGameMessage(Task &t);
	void processDbServerMessage(Task &t);
	void processMasterMessage(Task &t);
	void processCenterMessage(Task &t);

public:
	std::atomic<bool> quit_{false};
	bool isRunning_ = true;
	TcpServer tcp_;
	std::unordered_map<std::string, uint64_t> accountList_;	 // 已在线的账号:账号:会话
	std::unordered_map<uint64_t, Account> accountData_;		 // 账号数据 会话:账号对象
	std::unordered_map<uint16_t, uint64_t> logicId2Session_; // 逻辑服服务器id->会话映射,跨服用
	std::unordered_map<uint64_t, uint16_t> session2LogicId_; // 会话映射->逻辑服服务器id,跨服用
	std::unordered_map<uint64_t, uint64_t> enter_;			 // 向db发送的进入游戏协议的玩家id->会话id,配合伪登入使用
	std::queue<Task> qt_;
	std::thread sqlThread_;
	std::atomic<bool> sqlt_{false};
	std::vector<std::string> manNames_;	  // 男性名字库
	std::vector<std::string> womanNames_; // 女性名字库


	std::map<uint16_t, FunctionPtr> cppProto_;
};

#define gMainThread MainThread::instance()