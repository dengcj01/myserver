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

#include "../../../libs/openssl/sha.h"
#include "../../../libs/openssl/pem.h"
#include "../../../libs/openssl/bio.h"
#include "../../../libs/openssl/evp.h"
#include "../../../libs/jemalloc/jemalloc.h"

std::queue<Task> gQueue;
std::mutex gMutex;
std::condition_variable gCondVar;

extern std::unordered_map<int64_t, TcpConnecter *> gClients;
extern pthread_spinlock_t gsp;
extern std::unordered_map<uint8_t, Client *> gServerClients;
extern std::mutex gClientMutex;
extern uint8_t gClientIdx;

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
	eventLoop_->updateEvent(channel_);
	channel_->setReadCb(std::bind(&TcpConnecter::onRead, this));
	channel_->setWriteCb(std::bind(&TcpConnecter::onWrite, this));
}

void TcpConnecter::initClient(Client *cli)
{
	channel_->setEvent(EPOLLOUT | EPOLLET);
	eventLoop_->updateEvent(channel_);
	channel_->setWriteCb(std::bind(&Client::conncetCallBack, cli));
}

int TcpConnecter::readline(int &pos, char *buf)
{
	int endPos = readBuff_.readPos();
	for (; pos < endPos; pos++)
	{
		char ch = readBuff_.getVal(pos);
		if (ch == '\r' && readBuff_.getVal(pos + 1) == '\n')
		{
			pos += 2;
			return pos;
		}
		else
		{
			*(buf++) = ch;
		}
	}
	return -1;
}

void TcpConnecter::base64Encode(char *inBuf, char *outBuf)
{
	BIO *head = BIO_new(BIO_f_base64());
	BIO *bmem = BIO_new(BIO_s_mem());
	BIO_push(head, bmem);

	int lens = strlen(inBuf);
	BIO_write(head, inBuf, lens);
	BIO_ctrl(head, BIO_CTRL_FLUSH, 0, 0);

	BUF_MEM *mem;
	BIO_get_mem_ptr(head, &mem);
	memcpy(outBuf, mem->data, mem->length);
	outBuf[mem->length - 1] = '\0';
	BIO_free_all(head);
}

void TcpConnecter::base64Decode(char *inBuf, int inLens, char *outBuf, int outLens)
{
	BIO *head = BIO_new(BIO_f_base64());
	BIO *bmem = BIO_new_mem_buf(inBuf, inLens);
	BIO_push(head, bmem);
	BIO_read(head, outBuf, outLens);
	BIO_free_all(head);
}

bool TcpConnecter::websocketShake()
{
	int endPos = readBuff_.readPos();
	int pos = 0;
	char buf[500] = {0};
	bool ok = false;

	while (pos < endPos)
	{
		readline(pos, buf);

		if (strstr(buf, "Sec-WebSocket-Key"))
		{
			char sha1Buf[128] = {0};
			char b64Buf[32] = {0};

			strcat(buf, "258EAFA5-E914-47DA-95CA-C5AB0DC85B11");
			char *p = buf + 19;
			SHA1((const unsigned char *)p, strlen(p), (unsigned char *)sha1Buf);
			base64Encode(sha1Buf, b64Buf);
			char resp[200] = {0};

			sprintf(resp, "HTTP/1.1 101 Switching Protocols\r\n"
						  "Upgrade: websocket\r\n"
						  "Connection: Upgrade\r\n"
						  "Sec-WebSocket-Accept: %s\r\n\r\n",
					b64Buf);
			nowWrite(resp, strlen(resp));
			ok = true;
		}
		memset(buf, 0, 500);
	}

	return ok;
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
			logInfo("parseWebsokcetShake err");
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
	int j = 0;
	uint8_t endPos = begin + 4;
	uint8_t masking[4];
	for (uint8_t i = begin; i < endPos; i++) // 读masking-key
	{
		masking[j++] = readBuff_.getVal(i, wPos);
	}

	/*
	original-octet-i：为原始数据的第 i 字节。

	transformed-octet-i：为转换后的数据的第 i 字节。

	j：为i mod 4的结果。

	masking-key-octet-j：为 mask key 第 j 字节。

	j                   = i MOD 4
	transformed-octet-i = original-octet-i XOR masking-key-octet-j


	*/

	// mask = 0;
	if (mask == 1)
	{
		char *p = readBuff_.data() + wPos + endPos; // 获取真实数据开始的地址
		for (uint64_t i = 0; i < plyloadLen; i++)	// 用掩码解析数据
		{
			p[i] = p[i] ^ masking[(i & 3)];
		}
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

	if (payloadLen < 126)
	{
		if (mdLen < (payloadLen + 4))
		{
			return;
		}
		headLen = 6;
		parseWebsokceMaskXor(2, mask, payloadLen, wPos);
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
		parseWebsokceMaskXor(4, mask, payloadLen, wPos);
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
		parseWebsokceMaskXor(10, mask, payloadLen, wPos);
	}

	uint64_t addPos = payloadLen + headLen;

	if (fin != 1)
	{
		if (!cacheBuff_)
		{
			cacheBuff_ = new Buffer();
		}
		cacheBuff_->copyData(readBuff_.data() + wPos + headLen, payloadLen);
		readBuff_.updateWritePos(addPos);
	}
	else
	{
		size_t dataLen = 0;
		char buf[1024*1024*1]={0};

		if (cacheBuff_)
		{
			size_t lens = cacheBuff_->readPos();
			size_t maxLen = lens + payloadLen;

			memcpy(buf, cacheBuff_->data(), lens);
			memcpy(buf, readBuff_.data() + headLen + wPos, payloadLen);

			dataLen = maxLen;
			delete cacheBuff_;
			cacheBuff_ = nullptr;
		}
		else
		{
			memcpy(buf, readBuff_.data() + headLen + wPos, payloadLen);
			dataLen = payloadLen;
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

		uint32_t nowLen = dataLen + 8 + 1;
		uint32_t maxLen = nowLen + 4;

		char *buf1 = (char *)je_malloc(maxLen);
		uint8_t status = 0;
		memcpy(buf1, &nowLen, 4);
		memcpy(buf1 + 4, &status, 1);
		memcpy(buf1 + 5, &sessionId_, 8);
		memcpy(buf1 + 13, buf, dataLen);

		Task t;
		t.data_ = buf1;
		t.len_ = maxLen;

		Client::getClient()->sendMessage2Server(t);
	}
}

char *TcpConnecter::shardingData(char *data, size_t dataLen, uint16_t messageId, uint32_t &outLen)
{
	uint64_t inLen = 2 + dataLen; // 协议id+消息

	if (inLen < 126)
	{
		uint32_t maxLen = inLen + 2;
		char *p = (char *)je_malloc(maxLen);
		memset(p, 0, maxLen);
		p[0] = (0x80 | 2);
		p[1] = inLen;
		memcpy(p + 2, &messageId, 2);
		memcpy(p + 4, data, dataLen);
		outLen = maxLen;
		return p;
	}
	else if (inLen <= 65535)
	{
		uint32_t maxLen = inLen + 4;
		char *p = (char *)je_malloc(maxLen);
		memset(p, 0, maxLen);
		p[0] = (0x80 | 2);
		p[1] = 126;
		uint16_t net16 = htobe16((uint16_t)inLen);
		memcpy(p + 2, &net16, 2);
		memcpy(p + 4, &messageId, 2);
		memcpy(p + 6, data, dataLen);
		outLen = maxLen;
		return p;
	}
	else
	{
		uint64_t maxLen = inLen + 10;
		char *p = (char *)je_malloc(maxLen);
		memset(p, 0, maxLen);
		p[0] = (0x80 | 2);
		p[1] = 127;
		uint64_t net64 = htobe64(inLen);
		memcpy(p + 2, &net64, 8);
		memcpy(p + 10, &messageId, 2);
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
	else
	{
		size_t rPos = readBuff_.readPos();
		size_t wPos = readBuff_.writePos();
		size_t curLen = rPos - wPos;

		if (curLen < 4)
		{
			return;
		}

		size_t dataLen = 0;
		char *curWritePos = readBuff_.getHeadPos(); // d+w
		memcpy(&dataLen, curWritePos, 4);
		//logInfo("aaaaaaa rpos:%d wpos:%d datalen:%d curlen:%d mod:%d", rPos, wPos, dataLen, curLen, mod_);
		if (dataLen <= 0)
		{
			setFinCloseFlag();
			return;
		}

		if (curLen - 4 >= dataLen)
		{
			Task t;
			char *buf = (char *)je_malloc(dataLen);
			memset(buf, 0, dataLen);
			memcpy(buf, curWritePos + 4, dataLen);

			t.data_ = buf;
			t.len_ = dataLen;
			t.opt_ = mod_;
			t.sessionId_ = sessionId_;
			t.ip_ = ip_;

			if(mod_ == ConType::ConType_client_gate1 ||
			   mod_ == ConType::ConType_client_gate3 ||
			   mod_ == ConType::ConType_client_gate2 ||
			   mod_ == ConType::ConType_client_gate4)
			   {
					uint8_t where = 0;
					memcpy(&where, buf, 1);
					uint64_t csessionId = 0;
					memcpy(&csessionId, buf + 1, 8);
					uint16_t messageId = 0;
					memcpy(&messageId, buf + 9, 2);

					//logInfo("parseMessage where:%d mess:%d", where, messageId);
					if (where == 0)
					{
						TcpConnecter *con = nullptr;

						pthread_spin_lock(&gsp);
						auto it = gClients.find(csessionId);
						if (it == gClients.end())
						{
							logInfo("send msg 2 client err, no find messageId = %llu", csessionId);
							pthread_spin_unlock(&gsp);
							return;
						}

						con = it->second;
						pthread_spin_unlock(&gsp);

						EventLoop *loop = con->getEventLoop();

						uint32_t maxLen = 0;
						char *buf1 = con->shardingData(buf+11, dataLen-11, messageId, maxLen);

						Task ts;
						ts.sessionId_ = csessionId;
						ts.data_ = buf1;
						ts.len_ = maxLen;

						//logInfo("---------frowardMessage2Client %d %d %d", dataLen,maxLen,messageId);

						loop->addMessage(ts);		
						loop->weakUp();					
					}
					else
					{
						std::unique_lock<std::mutex> lk(gMutex);
						gQueue.emplace(std::move(t));
						lk.unlock();
						gCondVar.notify_one();
					}
			   }
			else
			{
				std::unique_lock<std::mutex> lk(gMutex);
				gQueue.emplace(std::move(t));
				lk.unlock();
				gCondVar.notify_one();				
			}   

			readBuff_.updateWritePos(4 + dataLen);

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
	
			parseMessage();
		}
	}
}

void TcpConnecter::onRead()
{
	readBuff_.expand();												  // len - r
	int ret = read(fd_, readBuff_.readData(), readBuff_.leftSpace()); // d+r len-r

	//logInfo("work thread onRead sess:%lu, ip:%s, port:%d, ret=%d, mod=%d", sessionId_, ip_.data(), port_, ret, mod_);

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

void TcpConnecter::nowWrite(char *data, size_t lens)
{
	// logInfo("TcpConnecter::nowWrite %ld", lens);
	if (finClose_)
	{
		logInfo("finClose_finClose_finClose_finClose_finClose_");
		return;
	}

	while (true)
	{
		size_t ret = write(fd_, data, lens);
		//logInfo("work thread nowWrite ip:%s, port:%d, ret:%d len:%d mod:%d errno:%d", ip_.data(), port_, ret, lens, mod_, errno);
		if (ret < 0)
		{
			if (errno == EWOULDBLOCK || errno == EAGAIN || errno == EINTR)
			{
				logInfo("1111111111111111111111111111");
				continue;
			}
			else
			{
				logInfo("------------nowWrite err %d", errno);
				return;
			}
		}
		else
		{
			if (ret < lens)
			{
				int leftLen = lens - ret;
				writeBuff_.copyData(data + ret, leftLen);
				channel_->setEvent(EPOLLIN | EPOLLOUT);
				eventLoop_->updateEvent(channel_, 3);
				isWriteing_ = true;
			}
		}
		return;
	}
}

void TcpConnecter::onWrite()
{
	if (finClose_)
	{
		return;
	}

	size_t validLen = writeBuff_.validWriteLen();			   // r-w
	size_t ret = write(fd_, writeBuff_.writeData(), validLen); // data+w
	// size_t ret = SSL_write(ssl_, writeBuff_.writeData(), validLen); // data+w
	//logInfo("work thread onWrite ret:%d validLen:%d %d errno:%d", ret, validLen, mod_, errno);
	if (ret < 0)
	{
		if (errno == EWOULDBLOCK || errno == EAGAIN || errno == EINTR)
		{
			logInfo("222222222222222222222222222222");
			return;
		}
		else
		{
			logInfo("---------------------------------onWrite err %d", errno);
			setFinCloseFlag();
			return;
		}
	}
	else
	{
		writeBuff_.updateWritePos(ret);
		if (validLen == ret)
		{
			if (eventLoop_->checkMessageProcessEnd(sessionId_))
			{
				isWriteing_ = false;
				channel_->setEvent(EPOLLIN);
				eventLoop_->updateEvent(channel_, 3);
			}
		}

		if (writeBuff_.readPos() == writeBuff_.writePos())
		{
			writeBuff_.reset();
		}
	}
}

void TcpConnecter::setFinCloseFlag()
{
	if (finClose_)
	{
		return;
	}

	finClose_ = true;
}

void TcpConnecter::realClose()
{

	eventLoop_->updateEvent(channel_, 2);

	close(fd_);

	if (closeCb_)
	{
		closeCb_(sessionId_);
	}
}
