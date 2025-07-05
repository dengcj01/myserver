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
//#include "../../../libs/jemalloc/jemalloc.h"
#include "../../common/net/TcpServer.h"
#include "../../common/net/Data.h"
#include "../../common/net/EventLoop.h"
#include "../../common/CommDefine.h"

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
	Account(const std::string &account, const std::string &pf, uint16_t fromServerId, uint16_t serverId, uint64_t sessionId, uint64_t csessionId) : account_(account),
																																					pf_(pf),
																																					fromServerId_(fromServerId),
																																					serverId_(serverId),
																																					sessionId_(sessionId),
																																					csessionId_(csessionId)
	{
	}

	std::string account_;
	std::string pf_;
	uint16_t fromServerId_;
	uint16_t serverId_;
	uint64_t sessionId_;
	uint64_t csessionId_;
	uint64_t pid_ = 0; // 玩家id
	uint8_t step_ = 0; // 登入步骤
	bool create_=false; // 是否收到了创角协议
	bool select_=false;
};

class MainThread : public Singleton<MainThread>
{
public:
	typedef void (*FunctionPtr)(uint64_t, uint64_t, char *, size_t);
	typedef void (*FunctionPtr1)(uint64_t, char *, size_t);
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
	void closeServer(uint8_t useDb = 0);
	bool initClient();
	void forceCloseSession(uint64_t sessionId, uint64_t csessionId, uint8_t reason);
	uint64_t accountIsOnline(const std::string &key);
	void onClose();
	bool checkPortUsed();


	void addMailLog(Player *player, const char *mail);
	bool cleanDb();
	bool loadGlobalData();
	void saveGlobalData(std::map<uint8_t, const char *> datas, uint8_t useDb = 0);
	void setEnterCnt(uint8_t cnt) {cnt_ = cnt;}
	const std::string createAccountKey(const std::string &account, const std::string &pf, uint16_t fromServerId)
	{
		return account + pf + std::to_string(fromServerId);
	}

	void save();
	void coreDump();


	void checkGm();
	void checkClose();
	void checkHttpGm();
	void removeAllAccountData();
	void noticeCloseGateSever();
	FunctionPtr getProtoFunc(uint16_t messageId);
	FunctionPtr1 getProtoFunc1(uint16_t messageId);
	void cacheCppProto();
	uint16_t getLogicServerId(uint64_t sessionId);
	uint64_t getLogicSessionId(uint16_t serverId);
	std::unordered_map<uint64_t, uint16_t> getLogicServerList();
	bool gLoadPlayers();
	int getMessageCnt();
	bool checkNetworkConnection(const char* str);
	void removeAccountByAccount(std::string account, std::string pf, int serverId);

	template <typename T>
	void packMessage(T &t, uint16_t messageId, Task &tk, const char* src)
	{
		/* 协议格式
		包头----消息id----数据
		*/
		uint32_t len = t.ByteSizeLong();
		uint32_t dataLen = len + 2;
		uint32_t maxLen = 4 + dataLen;

		char *buf = (char *)malloc(maxLen);

		uint32_t netDataLen = htonl(dataLen);	
		memcpy(buf, &netDataLen, 4);

		uint16_t netMessageId = htons(messageId);
		memcpy(buf + 4, &netMessageId, 2);
		
		t.SerializeToArray(buf + 6, len);

		tk.data_ = buf;
		tk.len_ = maxLen;
		//logInfo("%s packMessage messid:%d len:%d datalen:%d maxlen:%d", src, messageId, len,dataLen,maxLen);
	}

	template <typename T>
	void sendMessage2DbServer(T &t, uint16_t messageId)
	{
		Task tk;
		packMessage(t, messageId, tk, "发消息给db进程");
		tk.todb_ = true;
		tcp_.sendMessage2DbServer(tk);
	}

	template <typename T>
	void sendMessage2LogServer(T &t, uint16_t messageId)
	{
		Task tk;
		packMessage(t, messageId, tk, "发消息给log进程");
		tcp_.sendMessage2LogServer(tk);
	}

	template <typename T>
	void sendMessage2MasterServer(T &t, uint16_t messageId)
	{
		Task tk;
		packMessage(t, messageId, tk, "发消息给主连服进程");
		tcp_.sendMessage2MasterServer(tk);
	}
	void sendMessage2Http(const char* host, const char* path, std::string data);



private:
	void processGateClientMessage(Task &t);
	void processLogicGameMessage(Task &t);
	void processDbServerMessage(Task &t);
	void processMasterMessage(Task &t);
	std::string resolveDomain(const std::string &domain);

public:
	std::atomic<bool> quit_{false};
	bool isRunning_ = true;
	uint8_t cnt_ = 0;
	TcpServer tcp_;
	std::unordered_map<std::string, uint64_t> accountList_;	 // 已在线的账号:账号:会话
	std::unordered_map<uint64_t, Account> accountData_;		 // 账号数据 会话:账号对象
	std::unordered_map<uint16_t, uint64_t> logicId2Session_; // 逻辑服服务器id->会话映射,跨服用
	std::unordered_map<uint64_t, uint16_t> session2LogicId_; // 会话映射->逻辑服服务器id,跨服用
	std::queue<Task> qt_;
	std::thread sqlThread_;
	std::atomic<bool> sqlt_{false};
	std::map<uint64_t, std::vector<std::string>> https_;


	std::map<uint16_t, FunctionPtr> cppProto_;
	std::map<uint16_t, FunctionPtr1> cppProto1_;
};

#define gMainThread MainThread::instance()