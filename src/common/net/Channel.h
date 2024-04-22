#pragma once

#include <functional>

class TcpConnecter;

class Channel
{
public:
	typedef std::function<void()> EventCallBack;
	Channel(int fd, int event=1, TcpConnecter *con=nullptr);
	~Channel();
	inline int getEvent() { return revent_; }
	inline int getFd() { return fd_; }
	void inline setFd(int fd) {fd_ = fd;}
	inline void setEvent(int event) { revent_ = event; }

	inline void setTcpConnecter(TcpConnecter *con) { con_ = con; }
	void onEvent();
	void setReadCb(EventCallBack cb) { readCb_ = std::move(cb); }
	void setWriteCb(EventCallBack cb) { writeCb_ = std::move(cb); }

private:
	int fd_;
	int revent_;
	TcpConnecter *con_;

	EventCallBack readCb_;
	EventCallBack writeCb_;
};
