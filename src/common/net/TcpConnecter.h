#pragma once

#include <string>
#include <functional>
#include <atomic>
#include "../../../libs/google/protobuf/dynamic_message.h"
#include "Buffer.h"

class Client;
class EventLoop;
class Channel;

class TcpConnecter
{
public:
	TcpConnecter(int fd, uint64_t sessionId, EventLoop *loop);
	~TcpConnecter();
	typedef std::function<void(uint64_t)> EventCallBack;
	typedef std::function<void()> ConnectFunc;

	void init();
	void setCloseCb(EventCallBack cb) { closeCb_ = std::move(cb); }
	inline Channel *getChannel() { return channel_; }
	inline EventLoop *getEventLoop() { return eventLoop_; }
	void nowWrite(char *data, size_t lens);
	//void nowWrite1(char *data, size_t lens);
	int getFd() { return fd_; }
	bool getFinCloseFlag() { return finClose_; }
	void setMod(uint8_t mod) {mod_ = mod;}
	uint8_t getMod() { return mod_; }
	inline uint64_t getSessionId() { return sessionId_; }
	inline void setSessionId(uint64_t sessionId) { sessionId_ = sessionId; }
	void initClient(Client *cli);
	void setIpAndPort(const char *ip, uint16_t port) { ip_ = ip, port_ = port; }

	// http
	void parseWebsokcetShake();
	bool isFullHttpMessage();
	int readline(int &pos, char *buf);
	bool websocketShake();
	void base64Encode(char *inBuf, char *outBuf);
	void base64Decode(char *inBuf, int inLens, char *outBuf, int outLens);
	void parseWebsokceMaskXor(uint8_t begin, uint8_t mask, size_t plyloadLen, size_t wPos);
	void parseWebsocket();
	char *shardingData(char* data, size_t dataLen, uint16_t messageId, uint32_t &outLen); // 默认二进制帧类型
	void realClose();

	const char *getIp() { return ip_.data(); }

	// void setSSL(SSL* ssl) {ssl_ = ssl;}

private:
	void onRead();
	void onWrite();
	void setFinCloseFlag();
	void parseMessage();

public:
	bool isWriteing_ = false;



private:
	bool finClose_=false; // 关闭标志
	bool shaked_=false;
	int fd_;
	std::string ip_;
	uint16_t port_;
	uint8_t mod_ = 1; 
	uint64_t sessionId_=0;
	EventLoop *eventLoop_=0;
	Channel *channel_=0;
	EventCallBack closeCb_;


	Buffer readBuff_;
	Buffer writeBuff_;
	Buffer* cacheBuff_=0;
	// SSL *ssl_;
};
