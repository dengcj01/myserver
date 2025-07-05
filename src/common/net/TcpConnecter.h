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
	typedef std::function<void(uint64_t, bool)> EventCallBack;
	typedef std::function<void()> ConnectFunc;

	void init();
	void setCloseCb(EventCallBack cb) { closeCb_ = std::move(cb); }
	inline Channel *getChannel() { return channel_; }
	inline EventLoop *getEventLoop() { return eventLoop_; }
	void nowWrite(const char *data, size_t lens, bool todb=false);
	//void nowWrite1(char *data, size_t lens);
	int getFd() { return fd_; }
	void setMod(uint8_t mod) {mod_ = mod;}
	uint8_t getMod() { return mod_; }
	inline uint64_t getSessionId() { return sessionId_; }
	inline void setSessionId(uint64_t sessionId) { sessionId_ = sessionId; }
	void setIpAndPort(const char *ip, uint16_t port) { ip_ = ip, port_ = port; }
	void setFinCloseFlag();
	void setIdx(uint8_t idx) {idx_ = idx;}
	void setLoopName(const std::string& name) {loopName_ = name;}
	std::string getLoopName() { return loopName_ ;}
	// http
	void parseWebsokcetShake();
	bool isFullHttpMessage();
	bool websocketShake();
	std::string base64Encode(const unsigned char *input, int length);
	void parseWebsokceMaskXor(uint8_t begin, uint8_t mask, size_t plyloadLen, size_t wPos);
	void parseWebsocket();
	char *shardingData(char* data, size_t dataLen, uint16_t messageId, uint64_t &outLen); // 默认二进制帧类型
	void realClose(bool notice = true);
	uint8_t getIdx() {return idx_;}
	const char *getIp() { return ip_.data(); }
	bool mallocOk() {return readBuff_.mallocOk();}



private:
	void onRead();
	void onWrite();
	void parseMessage();

public:
	bool isWriteing_ = false;
	std::string heart_;
	std::atomic<bool> finClose_{false}; // 关闭标志

private:
	bool shaked_=false;
	int fd_;
	std::string loopName_;
	std::string ip_;
	uint16_t port_;
	uint8_t mod_ = 1; 
	uint8_t idx_ = 0;
	uint64_t sessionId_=0;
	EventLoop *eventLoop_=0;
	Channel *channel_=0;
	EventCallBack closeCb_;

	Buffer readBuff_;
	Buffer writeBuff_;
	Buffer* cacheBuff_=0;
	
	// SSL *ssl_;
};
