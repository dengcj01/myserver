#pragma once
#include <string.h>
#include <atomic>
#include <queue>
#include <unordered_map>
#include <string>
#include "../../common/Singleton.h"
#include "../../common/net/TcpServer.h"
#include "../../common/net/Data.h"
//#include "../../../libs/jemalloc/jemalloc.h"

class Player;



class MainThread : public Singleton<MainThread>
{
public:
	~MainThread();
	void start(uint16_t port);
	void closeServer();
	uint8_t getDbKeyType(uint64_t pid, const char* key);

	template<typename T>
	void send2Game(T& t, uint16_t messageId, uint64_t sessionId)
	{
		/* 协议格式
		包头-------消息id---------数据
		*/
		uint32_t len = t.ByteSizeLong();
		uint32_t dataLen = 2 + len; 
		uint32_t maxLen = dataLen + 4; 
		char *buf = (char *)malloc(maxLen);

		uint32_t netDataLen = htonl(dataLen);
		memcpy(buf, &netDataLen, 4);


		uint16_t netMessageId = htons(messageId);
		memcpy(buf + 4, &netMessageId, 2);

		t.SerializeToArray(buf + 6, len);

		Task tk;
		tk.data_ = buf;
		tk.len_ = maxLen;
		tk.sessionId_ = sessionId;

		tcp_.sendMessage2Game(tk);
	}


	void processClientMessage(Task& t);
	bool running_ = true;
	std::atomic<bool> quit_{false};
	TcpServer tcp_;
	std::queue<Task> qt_;
	std::thread sqlThread_;
	std::unordered_map<std::string, uint8_t> dbKey_;
};

#define gMainThread MainThread::instance()