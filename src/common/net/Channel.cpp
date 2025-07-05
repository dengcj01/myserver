
#include "Channel.h"
#include "TcpConnecter.h"
#include <stdio.h>

#include <sys/epoll.h>

#include "../Tools.hpp"
#include "../log/Log.h"

Channel::Channel(int fd, int event, TcpConnecter *con):
fd_(fd),
revent_(event),
con_(con)
{
	
}

Channel::~Channel()
{
	con_ = nullptr;
}

void Channel::setEvent(int event)
{
	revent_ = event;
}

void Channel::onEvent(uint8_t mod)
{

	if(con_ && con_->finClose_.load())
	{
		con_->realClose();
	}
	else
	{
		if ((revent_ & EPOLLIN) && readCb_) // EPOLLIN
		{
			readCb_();
		}
	
		if ((revent_ & EPOLLOUT) && writeCb_) // EPOLLOUT
		{
			writeCb_();
		}
	
		if(con_ && con_->finClose_.load())
		{
			con_->realClose();
		}
	}

}
