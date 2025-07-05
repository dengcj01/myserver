#include "TcpConnecter.h"

#include <sys/epoll.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <endian.h>
#include <errno.h>

#include <thread>
#include <iostream>
#include <condition_variable>
#include <mutex>
#include <queue>

#include "../log/Log.h"
#include "../Client.h"
#include "Channel.h"
#include "EventLoop.h"
#include "Data.h"
#include "../Timer.hpp"
#include "../Tools.hpp"
#include "../ProtoIdDef.h"

#include "../../../libs/openssl/sha.h"
#include "../../../libs/openssl/pem.h"
#include "../../../libs/openssl/bio.h"
#include "../../../libs/openssl/evp.h"
//#include "../../../libs/jemalloc/jemalloc.h"
#include "TcpServer.h"

#include "../ParseConfig.hpp"

#include "../pb/Login.pb.h"
#include "../pb/Player.pb.h"

std::queue<Task> gQueue;
std::mutex gMutex;
std::condition_variable gCondVar;


extern pthread_spinlock_t gsp;
extern std::unordered_map<uint8_t, Client *> gServerClients;


const uint8_t HeardDefaultTime1 = 40; // 默认心跳,前端是10秒,后端延迟点
const uint32_t MaxCacheLen = 1024*1024*1; // 分包最大支持内存 


TcpConnecter::TcpConnecter(int fd, uint64_t sessionId, EventLoop *loop) : fd_(fd),
																		  sessionId_(sessionId),
																		  eventLoop_(loop)
{
	channel_ = new Channel(fd_, 1, this);
}

TcpConnecter::~TcpConnecter()
{
	if (channel_)
	{
		delete channel_;
		channel_ = nullptr;
	}
	eventLoop_ = nullptr;

	if (cacheBuff_)
	{
		delete cacheBuff_;
		cacheBuff_ = nullptr;
	}
}

void TcpConnecter::init()
{
	channel_->setReadCb(std::bind(&TcpConnecter::onRead, this));
	channel_->setWriteCb(std::bind(&TcpConnecter::onWrite, this));
	eventLoop_->updateEvent(channel_);
}


std::string TcpConnecter::base64Encode(const unsigned char *input, int length)
{
	BIO *bio, *b64;
	BUF_MEM *bufferPtr;

	b64 = BIO_new(BIO_f_base64());
	bio = BIO_new(BIO_s_mem());
	bio = BIO_push(b64, bio);

	BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);
	BIO_write(bio, input, length);
	(void)BIO_flush(bio);

	BIO_get_mem_ptr(bio, &bufferPtr);
	(void)BIO_set_close(bio, BIO_NOCLOSE);
	BIO_free_all(bio);

	std::string result(bufferPtr->data, bufferPtr->length);
	return result;
}

bool TcpConnecter::websocketShake()
{
	std::string clientKey;
	const char *searchKey = "Sec-WebSocket-Key: ";
	char *key_start = strstr(readBuff_.data(), searchKey);
	if (key_start != nullptr)
	{
		key_start += strlen(searchKey);
		char *key_end = strchr(key_start, '\r');
		if (key_end != nullptr)
		{
			clientKey.assign(key_start, key_end - key_start);
		}
		else
		{
			return false;
		}
	}
	else
	{
		return false;
	}

	std::string magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
	std::string concat = clientKey + magic;

	unsigned char hash[SHA_DIGEST_LENGTH];
	SHA1(reinterpret_cast<const unsigned char *>(concat.c_str()), concat.length(), hash);

	std::string acceptKey = base64Encode(hash, SHA_DIGEST_LENGTH);

	std::string res = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: " + acceptKey + "\r\n\r\n";

	nowWrite(res.data(), res.length());

	return true;
}

void TcpConnecter::parseWebsokcetShake()
{
	if (!shaked_)
	{
		if (!isFullHttpMessage())
		{
			return;
		}

		if (!websocketShake())
		{
			setFinCloseFlag();
			return;
		}
		else
		{
			shaked_ = true;
			readBuff_.cleanMem();
		}
	}
	else
	{
		parseWebsocket();
	}
}

void TcpConnecter::parseWebsokceMaskXor(uint8_t begin, uint8_t mask, size_t plyloadLen, size_t wPos)
{
	/*
	original-octet-i：为原始数据的第 i 字节。
	transformed-octet-i：为转换后的数据的第 i 字节。
	j：为i mod 4的结果。
	masking-key-octet-j：为 mask key 第 j 字节。
	j                   = i MOD 4
	transformed-octet-i = original-octet-i XOR masking-key-octet-j
	*/


	if(mask == 0)
	{
		return;
	}

	//int j = 0;
	uint8_t endPos = begin + 4;
	uint8_t masking[4];
	char* sp = readBuff_.data() + wPos + begin;

	memcpy(masking, sp, 4);
	// for (uint8_t i = begin; i < endPos; i++) // 读masking-key
	// {
	// 	masking[j++] = readBuff_.getVal(i, wPos);

	// }                                                                                                                   

	char *p = readBuff_.data() + wPos + endPos; // 获取真实数据开始的地址
	for (uint64_t i = 0; i < plyloadLen; i++)	// 用掩码解析数据
	{
		p[i] = p[i] ^ masking[(i & 3)];
	}



}

void TcpConnecter::parseWebsocket()
{
	//----------------------------------------------<125
	/*                     1字节              2字节             3字节         4字节
	0	1	2	3		4 5 6 7  0     1 2 3 4 5 6 7    0 1 2 3 4 5 6 7  0 1 2 3 4 5 6 7
	fin	rsv	rsv	rsv		opocde	 mask  真实数据的长度     masking-key---------------------
	-------------------------------------masking-key    真实数据-------------------------
	*/

	//----------------------------------------------126
	/*                     1字节              2字节             3字节         4字节
	0	1	2	3		4 5 6 7  0     1 2 3 4 5 6 7    0 1 2 3 4 5 6 7  0 1 2 3 4 5 6 7
	fin	rsv	rsv	rsv		opocde	 mask  真实数据长度标记   真实数据的长度------------------
	-------------------------------masking-key-----------------------------------------
	真实数据----------------------------------------------------------------------------
	*/

	//----------------------------------------------127
	/*                     1字节              2字节             3字节         4字节
	0	1	2	3		4 5 6 7  0     1 2 3 4 5 6 7    0 1 2 3 4 5 6 7  0 1 2 3 4 5 6 7
	fin	rsv	rsv	rsv		opocde	 mask  真实数据长度标记   真实数据的长度开始---------------
	--------------------------------------------------   真实数据的长度-------------------
	----------------------------------真实数据的长度结束   masking-key--------------------
	masking-key---------------------------------------	  真实数据-----------------------
	*/

	/** Payload len
	值在0-125，则是payload是真实数据长度。
	>125时，Payload len仅仅作为一个标记区分值
	是126，则后面2个字节形成的16位无符号整型数的值是真正数据的长度。网络字节序，需要转换。
	是127，则后面8个字节形成的64位无符号整型数的值是真正数据的长度。网络字节序，需要转换
	*/

	size_t wPos = readBuff_.writePos();
	size_t rPos = readBuff_.readPos();
	size_t curLen = rPos - wPos;

	if (curLen < 2) // 不足2字节,不解析
	{
		return;
	}

	uint8_t firstBitData = readBuff_.getVal(0, wPos);
	uint8_t fin = (firstBitData & 0x80) >> 7;
	uint8_t opcode = firstBitData & 0xF;

	uint8_t secondBitData = readBuff_.getVal(1, wPos);
	uint8_t mask = (secondBitData & 0x80) >> 7;
	uint64_t payloadLen = secondBitData & 0x7F;

	size_t mdLen = curLen - 2;
	uint32_t headLen;
	// logInfo("headheadheadheadheadhead sess:%lu, fin:%d, opcode:%d, mask:%d, payload:%ld  %d %d %ld,\n", sessionId_, fin, opcode, mask, payloadLen, rPos, wPos, readBuff_.size());

	if (opcode == 8) // 客户端断开连接
	{
		setFinCloseFlag();
		return;
	}

	uint8_t spos = 2;

	if (payloadLen < 126)
	{
		if (mdLen < (payloadLen + 4))
		{
			return;
		}
		headLen = 6;
	}
	else if (payloadLen == 126)
	{
		uint16_t len;
		memcpy(&len, readBuff_.data() + wPos + 2, 2);
		payloadLen = ntohs(len);

		if (mdLen < (payloadLen + 4 + 2))
		{
			return;
		}

		headLen = 8;
		spos = 4;
	}
	else
	{
		uint64_t len;
		memcpy(&len, readBuff_.data() + wPos + 2, 8);

		payloadLen = be64toh(len);

		if (mdLen < (payloadLen + 4 + 8))
		{
			return;
		}

		headLen = 14;
		spos = 10;

	}
	parseWebsokceMaskXor(spos, mask, payloadLen, wPos);

	uint64_t addPos = payloadLen + headLen;

	if (fin != 1)
	{
		if (!cacheBuff_)
		{
			cacheBuff_ = new Buffer();
		}
		cacheBuff_->copyData(readBuff_.data() + wPos + headLen, payloadLen);
		readBuff_.updateWritePos(addPos);
		parseWebsocket();
	}
	else
	{
		size_t dataLen = 0;
		char buf[MaxCacheLen]={0};

		if (cacheBuff_)
		{
			size_t lens = cacheBuff_->readPos();
			size_t maxLen = lens + payloadLen;
			if(maxLen >= MaxCacheLen)
			{
				delete cacheBuff_;
				cacheBuff_ = nullptr;

				setFinCloseFlag();
				return;
			}

			memcpy(buf, cacheBuff_->data(), lens);
			memcpy(buf + lens, readBuff_.data() + headLen + wPos, payloadLen);

			dataLen = maxLen;
			delete cacheBuff_;
			cacheBuff_ = nullptr;
		}
		else
		{
			memcpy(buf, readBuff_.data() + headLen + wPos, payloadLen);
			dataLen = payloadLen;
		}




		uint16_t clientMessId = 0;
		memcpy(&clientMessId, buf, 2);

		uint16_t hid = ntohs(clientMessId);
		if(hid == (uint16_t)ProtoIdDef::ReqHeartTick)
		{
			//logInfo("网关服务器收到前端消息 messid:%d sess:%llu, mod:%d", hid, sessionId_, mod_);
			if(heart_.empty())
			{
				Args *args = (Args *)malloc(sizeof(Args));
				args->csessionId = sessionId_;
				heart_ = gTimer.add(HeardDefaultTime1, &TcpServer::headTickCallback, args);
				//logInfo("第一次收到客户端心跳包 %llu %s", sessionId_, heart_.data());
			}
			else
			{
				Args *args = (Args *)malloc(sizeof(Args));
				args->csessionId = sessionId_;
				heart_ = gTimer.updateTime(heart_.c_str(), HeardDefaultTime1, &TcpServer::headTickCallback, args);
				//logInfo("再次收到客户端心跳包 %llu", sessionId_, heart_.data());
			}

			{
				std::unique_ptr<ResHeartTick> rsp(std::make_unique<ResHeartTick>());
				rsp->set_nowtime(gTools.getNowTime());

				size_t heatLen = rsp->ByteSizeLong();
				char tmp[10] = {0};
				rsp->SerializeToArray(tmp, heatLen);
				
				uint64_t outLen = 0;
				char * buf1 = shardingData(tmp, heatLen, (uint16_t)ProtoIdDef::ResHeartTick, outLen);

				Task ts1;
				ts1.sessionId_ = sessionId_;
				ts1.data_ = buf1;
				ts1.len_ = outLen;
				eventLoop_->addMessage(ts1);	
				//logInfo("发送了心跳包给前端 %llu", sessionId_);
			}
		}
		else
		{

			// ReqLoginAuth obj;
 			// std::cout<<"res:"<<obj.ParseFromArray(buf + 2, dataLen - 2)<<std::endl;
			// std::cout<<"serverid:"<<obj.serverid()<<std::endl;
			// std::cout<<"account:"<<obj.account()<<std::endl;
			// std::cout<<"password:"<<obj.password()<<std::endl;
			// std::cout<<"pf:"<<obj.pf()<<std::endl;
			// std::cout<<"fromServerId:"<<obj.fromserverid()<<std::endl;


			uint32_t nowLen = dataLen + 8 + 1;
			uint32_t maxLen = nowLen + 4;
			char *buf1 = (char *)malloc(maxLen);

			uint32_t netNowLen = htonl(nowLen);
			memcpy(buf1, &netNowLen, 4);

			uint8_t status = 0;
			memcpy(buf1 + 4, &status, 1);

			uint64_t netSessionId = htobe64(sessionId_);
			memcpy(buf1 + 5, &netSessionId, 8);

			memcpy(buf1 + 13, buf, dataLen);

			Task t;
			t.data_ = buf1;
			t.len_ = maxLen;

			Client* c = gServerClients[idx_];
			if(c)
			{
				logInfo("准备发送给网关客户端 sess:%lu %d", sessionId_, idx_);
				c->sendMessage2Server(t);
			}
			else
			{
				logInfo("网关客户端找不到这个索引的 %d", idx_);
			}	
		}	

		readBuff_.updateWritePos(addPos);
 
		wPos = readBuff_.writePos();
		if (rPos == wPos)
		{
			readBuff_.reset();
		}
		else
		{
			size_t effectiveLen = rPos - wPos;
			if (wPos > effectiveLen && wPos >= 1024)
			{
				readBuff_.moveBuff();
			}
		}


	}
}

char *TcpConnecter::shardingData(char *data, size_t dataLen, uint16_t messageId, uint64_t &outLen)
{
	uint64_t inLen = 2 + dataLen; // 协议id+消息

	if (inLen < 126)
	{
		uint32_t maxLen = inLen + 2;
		char *p = (char *)malloc(maxLen);
		memset(p, 0, maxLen);
		p[0] = (0x80 | 2);
		p[1] = inLen;
		uint16_t netMessId = htons(messageId);
		memcpy(p + 2, &netMessId, 2);
		memcpy(p + 4, data, dataLen);
		outLen = maxLen;
		return p;
	}
	else if (inLen <= 65535)
	{
		uint32_t maxLen = inLen + 4;
		char *p = (char *)malloc(maxLen);
		memset(p, 0, maxLen);
		p[0] = (0x80 | 2);
		p[1] = 126;
		uint16_t net16 = htons((uint16_t)inLen);
		memcpy(p + 2, &net16, 2);
		uint16_t netMessId = htons(messageId);
		memcpy(p + 4, &netMessId, 2);
		memcpy(p + 6, data, dataLen);
		outLen = maxLen;
		return p;
	}
	else
	{
		uint64_t maxLen = inLen + 10;
		char *p = (char *)malloc(maxLen);
		memset(p, 0, maxLen);
		p[0] = (0x80 | 2);
		p[1] = 127;
		uint64_t net64 = htobe64(inLen);
		memcpy(p + 2, &net64, 8);
		uint16_t netMessId = htons(messageId);
		memcpy(p + 10, &netMessId, 2);
		memcpy(p + 12, data, dataLen);
		outLen = maxLen;
		return p;
	}
}

bool TcpConnecter::isFullHttpMessage()
{
	size_t endPos = readBuff_.readPos();
	if (endPos < 4)
	{
		return false;
	}

	//logInfo(readBuff_.data());

	for (size_t i = 0; i < endPos; i++)
	{
		uint16_t sec = i + 1;
		uint16_t thr = i + 2;
		uint16_t fou = i + 3;

		if (readBuff_.getVal(i) == '\r' &&
			sec <= endPos && readBuff_.getVal(sec) == '\n' &&
			thr <= endPos && readBuff_.getVal(thr) == '\r' &&
			fou <= endPos && readBuff_.getVal(fou) == '\n')
		{
			return true;
		}
	}
	return false;
}

void TcpConnecter::parseMessage()
{
	if (mod_ == ConType::ConType_gate_server)
	{
		parseWebsokcetShake();
	}
	else if(mod_ == ConType::ConType_http_client)
	{
		logInfo("%s", readBuff_.data());
		readBuff_.reset();
	}
	else
	{

		size_t rPos = readBuff_.readPos();
		size_t wPos = readBuff_.writePos();
		size_t curLen = rPos - wPos;

		if (curLen < 4)
		{
			return;
		}

		size_t netDataLen = 0;
		char *curWritePos = readBuff_.getHeadPos(); // d+w
		memcpy(&netDataLen, curWritePos, 4);

		size_t bodyAndMessIdLen = ntohl(netDataLen);
		
		//logInfo("aaaaaaa rpos:%d wpos:%d datalen:%d curlen:%d mod:%d", rPos, wPos, dataLen, curLen, mod_);
		if (bodyAndMessIdLen <= 0)
		{
			setFinCloseFlag();
			return;
		}

		if (curLen - 4 >= bodyAndMessIdLen)
		{

			size_t nowPackLen = bodyAndMessIdLen + 4; // 当前一个完整包的长度
			char* startPos = curWritePos + 4;
			bool isClient = (mod_ == ConType::ConType_client_gate1 || mod_ == ConType::ConType_client_gate3 || mod_ == ConType::ConType_client_gate2 || mod_ == ConType::ConType_client_gate4);
			if(isClient)
			{
				
				uint8_t where = 0;
				memcpy(&where, startPos, 1);

				uint64_t csessionId = 0;
				memcpy(&csessionId, startPos + 1, 8);
				csessionId = be64toh(csessionId);
				
				uint16_t messageId = 0;
				memcpy(&messageId, startPos + 9, 2);
				messageId = ntohs(messageId);

				//logInfo("收到游戏服消息 mess:%d where:%d bodyAndMessIdLen:%d mod:%d sess:%llu curlen:%d idx:%d", messageId, where, bodyAndMessIdLen, mod_, csessionId, curLen, idx_);


				/*tcp 网关服务器类型 */
				if (where == 0) // 网关收到消息游戏服逻辑消息，0表示需要转发给客户端, 非0表示需要网关服务器自己处理
				{				
					EventLoop* loop = TcpServer::getLoop(csessionId);
					if(loop)
					{
						// 网关服务器是websocket时
						{
							uint64_t outLen = 0;
							char* buf = shardingData(startPos + 11, bodyAndMessIdLen - 11, messageId, outLen);
							Task ts;
							ts.sessionId_ = csessionId;
							ts.data_ = buf;
							ts.len_ = outLen;
							loop->addMessage(ts);	
							loop->weakUp();	
						}


						// 网关服务器是tcp时
						// {
						// 	size_t dataLen = bodyAndMessIdLen - 9;
						// 	size_t maxLen = dataLen + 4;
						// 	size_t netNowLen = htonl(dataLen);
	
						// 	char *buf = (char*)malloc(maxLen);
						// 	memcpy(buf, &netNowLen, 4);
						// 	memcpy(buf + 4, startPos + 9, dataLen);
	
						// 	Task ts;
						// 	ts.sessionId_ = csessionId;
						// 	ts.data_ = buf;
						// 	ts.len_ = maxLen;
	
						// 	//logInfo("parseclient555 mod:%d %s", mod_, loop->getName().data());
						// 	loop->addMessage(ts);		
						// 	//logInfo("parseclient555111 mod:%d", mod_);
						// 	loop->weakUp();	
						// 	//logInfo("parseclient666 mod:%d %s", mod_, loop->getName().data());
						// 	//logInfo("游戏服消息转给前端 sess:%llu, mess:%d where:%d maxLen:%d mod:%d", csessionId, messageId, where, maxLen,mod_);
						// }

					}
				}
				else
				{

					char *buf = (char*)malloc(bodyAndMessIdLen);
					memcpy(buf, startPos, bodyAndMessIdLen);				


					Task t;
					t.data_ = buf;
					t.len_ = bodyAndMessIdLen;
					t.opt_ = mod_;
					t.sessionId_ = sessionId_;
					
					std::unique_lock<std::mutex> lk(gMutex);
					gQueue.emplace(std::move(t));
					lk.unlock();
					gCondVar.notify_one();

				}				
			}
			else //不是网关客户端
			{
				// 网关服务器收到客户端消息
				if (mod_ == ConType::ConType_gate_tcp_server)
				{
					uint16_t clientMessId = 0;
					memcpy(&clientMessId, startPos, 2);
					
					uint16_t hid = ntohs(clientMessId);
					//logInfo("网关服务器收到前端消息 sess:%llu messid:%d mod:%d %s", sessionId_, hid, mod_, loopName_.data());
					
					if(hid == (uint16_t)ProtoIdDef::ReqHeartTick)
					{
						//logInfo("网关服务器收到前端消息 messid:%d sess:%llu, mod:%d", hid, sessionId_, mod_);
						if(heart_.empty())
						{
							Args *args = (Args *)malloc(sizeof(Args));
							args->csessionId = sessionId_;
							heart_ = gTimer.add(HeardDefaultTime1, &TcpServer::headTickCallback, args);
							//logInfo("第一次收到客户端心跳包 %llu %s", sessionId_, heart_.data());
						}
						else
						{
							Args *args = (Args *)malloc(sizeof(Args));
							args->csessionId = sessionId_;
							heart_ = gTimer.updateTime(heart_.c_str(), HeardDefaultTime1, &TcpServer::headTickCallback, args);
							//logInfo("再次收到客户端心跳包 %llu", sessionId_, heart_.data());
						}

						{
							std::unique_ptr<ResHeartTick> rsp(std::make_unique<ResHeartTick>());
							rsp->set_nowtime(gTools.getNowTime());

							size_t heatLen = rsp->ByteSizeLong();
							uint32_t heartDataLen = heatLen + 2;
							uint32_t hearMaxLen = heartDataLen + 4;

							char *buf1 = (char *)malloc(hearMaxLen);

							size_t netHeartDataLen= htonl(heartDataLen);
							memcpy(buf1, &netHeartDataLen, 4);

							uint16_t netMessageId = htons((uint16_t)ProtoIdDef::ResHeartTick);
							memcpy(buf1 + 4, &netMessageId, 2);

							rsp->SerializeToArray(buf1 + 6, heatLen);

							Task ts1;
							ts1.sessionId_ = sessionId_;
							ts1.data_ = buf1;
							ts1.len_ = hearMaxLen;
							eventLoop_->addMessage(ts1);	
							//logInfo("发送了心跳包给前端 %llu", sessionId_);
						}
					}
					else
					{
						logInfo("网关服务器收到前端消息 sess:%llu messid:%d mod:%d %s", sessionId_, hid, mod_, loopName_.data());

						uint32_t nowLen = bodyAndMessIdLen + 8 + 1;
						uint32_t maxLen = nowLen + 4;

						char *buf = (char *)malloc(maxLen);
				
						uint32_t netNowLen = htonl(nowLen);
						memcpy(buf, &netNowLen, 4);
	
						uint8_t status = 0;
						memcpy(buf + 4, &status, 1);
	
						uint64_t netSessionId = htobe64(sessionId_);
						memcpy(buf + 5, &netSessionId, 8);
	
						memcpy(buf + 13, startPos, bodyAndMessIdLen);

						Task t;
						t.data_ = buf;
						t.len_ = maxLen;

						Client* c = gServerClients[idx_];
						if(c)
						{
							//logInfo("准备发送给网关客户端 sess:%lu %d", sessionId_, idx_);
							c->sendMessage2Server(t);
						}
						else
						{
							logInfo("网关客户端找不到这个索引的 %d", idx_);
						}					
					}		
				}	
				else
				{
					if(mod_ == ConType_game_server) // gameserver 服务器收到网关消息
					{

						char *buf = (char *)malloc(bodyAndMessIdLen);
						memcpy(buf, startPos, bodyAndMessIdLen);

						Task t;
						t.data_ = buf;
						t.len_ = bodyAndMessIdLen;
						t.opt_ = mod_;
						t.sessionId_ = sessionId_;
						t.ip_ = ip_;

						uint8_t status = 0;
						memcpy(&status, buf, 1);


						uint16_t messid = 0;
						memcpy(&messid, startPos+9, 2);
						messid = ntohs(messid);

						logInfo("服务器收到网关消息 prtoid: %d status:%d mod:%d",messid, status, mod_);

						std::unique_lock<std::mutex> lk(gMutex);
						gQueue.emplace(std::move(t));
						lk.unlock();
						gCondVar.notify_one();

					}
					else
					{
						if(mod_ == ConType_db_server)
						{
							uint16_t netMid = 0;
							memcpy(&netMid, startPos, 2);
							netMid = ntohs(netMid);
							logInfo("db收到game消息 protoid: %d", netMid);
						}

						char *buf = (char *)malloc(bodyAndMessIdLen); // db进程 or log进程 or gameClient or master
						memcpy(buf, startPos, bodyAndMessIdLen);

						Task t;
						t.data_ = buf;
						t.len_ = bodyAndMessIdLen;
						t.opt_ = mod_;
						t.sessionId_ = sessionId_;
						t.ip_ = ip_;

						std::unique_lock<std::mutex> lk(gMutex);
						gQueue.emplace(std::move(t));
						lk.unlock();
						gCondVar.notify_one();	
					}
				}					
			}

			readBuff_.updateWritePos(nowPackLen);

			wPos = readBuff_.writePos();
			if (rPos == wPos)
			{
				//logInfo("-----------------------解析了一个完整的数据包 %d", mod_);
				readBuff_.reset();
			}
			else
			{
				size_t effectiveLen = rPos - wPos;
				if (wPos > effectiveLen && wPos >= 1024)
				{
					readBuff_.moveBuff();
				}
			}			

			parseMessage();
		}
	}
}

void TcpConnecter::onRead()
{
	readBuff_.expand();												  
	int left = readBuff_.leftSpace(); // len - r
	int ret = read(fd_, readBuff_.readData(), left); // d+r len-r


	if (ret < 0)
	{
		if (errno == EWOULDBLOCK || errno == EAGAIN || errno == EINTR)
		{
			return;
		}
		else
		{
			setFinCloseFlag();
			return;
		}
	}
	else if (ret == 0)
	{
		setFinCloseFlag();
	}
	else
	{
		readBuff_.updateReadPos(ret); // r+=ret

		parseMessage();


	}
}

void TcpConnecter::nowWrite(const char *data, size_t lens, bool todb)
{
	if (finClose_.load())
	{
		return;
	}

	while (true)
	{
		size_t ret = write(fd_, data, lens);
		if (ret < 0)
		{
			if (errno == EWOULDBLOCK || errno == EAGAIN || errno == EINTR)
			{
				logInfo("nowWritenowWritenowWritenowWritenowWritenowWritenowWritenowWritenowWritenowWritenowWritenowWritenowWritenowWrite %d", mod_);
				continue; 
			}
			else
			{
				logInfo("------------nowWrite err mod:%d %d ", mod_, errno);
				return;
			}
		}
		else
		{
			if(mod_ == ConType_db_client && todb)
			{
				logInfo("TcpConnecter::nowWrite %ld %ld", lens, ret);
			}
			
			if (ret < lens)
			{
			
				int leftLen = lens - ret;
				writeBuff_.copyData(data + ret, leftLen);
				channel_->setEvent(EPOLLIN | EPOLLOUT);
				eventLoop_->updateEvent(channel_, EPOLL_CTL_MOD);
				isWriteing_ = true;					
			}
		}
		return;
	}
}

void TcpConnecter::onWrite()
{
	if (finClose_.load())
	{
		return;
	}

	size_t validLen = writeBuff_.validWriteLen();			   // r-w
	size_t ret = write(fd_, writeBuff_.writeData(), validLen); // data+w

	if (ret < 0)
	{
		if (errno == EWOULDBLOCK || errno == EAGAIN || errno == EINTR)
		{
			return;
		}
		else
		{
			setFinCloseFlag();
			return;
		}
	}
	else
	{
		writeBuff_.updateWritePos(ret);
		if (validLen == ret)
		{
			isWriteing_ = false;

			channel_->setEvent(EPOLLIN);
			eventLoop_->updateEvent(channel_, EPOLL_CTL_MOD);

		}

		if (writeBuff_.readPos() == writeBuff_.writePos())
		{

			writeBuff_.reset();
		}
	}
}

void TcpConnecter::setFinCloseFlag()
{
	finClose_ = true;
}

void TcpConnecter::realClose(bool notice)
{
	if (closeCb_)
	{
		closeCb_(sessionId_, notice);
	}
}


