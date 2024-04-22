#include "Channel.h"
#include "TcpConnecter.h"
#include <stdio.h>





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

void Channel::onEvent()
{

	if ((revent_ & 1) && readCb_) // EPOLLIN
	{
		readCb_();
	}

	if ((revent_ & 4) && writeCb_) // EPOLLOUT
	{
		writeCb_();
	}

	if (con_ && con_->getFinCloseFlag())
	{
		con_->realClose();
	}
}
