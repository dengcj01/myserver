

#include <unistd.h>
#include <sys/socket.h>
#include <string.h>
#include <sys/syscall.h>
#include <fcntl.h>
#include <unordered_map>
#include <condition_variable>
#include <mutex>
#include <queue>

#include "Client.h"
#include "net/Data.h"
#include "net/EventLoop.h"
#include "net/Channel.h"
#include "log/Log.h"

#include "net/TcpConnecter.h"
#include "../libs/jemalloc/jemalloc.h"
#include "Timer.hpp"
#include "CommDefine.h"

#include "ParseConfig.hpp"

std::atomic<bool> gameDumpFlag_{false};


std::unordered_map<uint8_t, Client *> gServerClients;



extern std::queue<Task> gQueue;
extern std::mutex gMutex;
extern std::condition_variable gCondVar;

uint64_t gClienAutoIncretId = 2;



Client::Client()
{

}

Client::~Client()
{
    if (con_)
    {
        delete con_;
        con_ = nullptr;
    }

    if (loop_)
    {
        delete loop_;
        loop_ = nullptr;
    }
}

void Client::quitClient()
{
    if (loop_)
    {
        loop_->quit_ = true;
        loop_->weakUp();
        ioThread_.join();
    }
}

void Client::init(uint8_t mod, uint16_t port, const char *ip)
{
    ip_ = ip;
    port_ = port;
    loop_ = new EventLoop();
    loop_->setMod(mod);
    mod_ = mod;
    Args *args = (Args *)malloc(sizeof(Args));
    args->obj_ = this;
    args->first_ = true;

    ioThread_ = std::thread([this]()
    { 
        loop_->startLoop(getName(true)); 
    });

    Client::staticConnectTimer(args);
    free(args);
}



int Client::tryConnect(bool first) 
{
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0)
    {
        if (first)
        {
            logQuit("tryConnect socket err");
            _exit(0);
            return 0;
        }
        else
        {
            return -1;
        }
    }

    fcntl(fd, F_SETFL, fcntl(fd, F_GETFL, 0) | O_NONBLOCK);

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(struct sockaddr_in));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port_);
    addr.sin_addr.s_addr = inet_addr(ip_.data());

    int ret = connect(fd, (struct sockaddr *)&addr, sizeof(struct sockaddr));
    if(ret == 0)
    {
        return fd;
    }

    if (errno != EINPROGRESS) 
    {
        close(fd);
        return -1;
    }
    
    return fd;
}
 
bool Client::checkConnected(int fd) 
{
    int err;
    socklen_t len = sizeof(err);
    if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &err, &len) < 0)
    {
        return false;
    }
    return err == 0;
}

void Client::staticConnectTimer(Args *args)
{
    Client *cli = (Client *)args->obj_;
    int fd = cli->tryConnect(args->first_);
    if(fd == -1)
    {
        Args *tmp = (Args *)malloc(sizeof(Args));
        tmp->obj_ = args->obj_;
        gTimer.add(1, &Client::staticConnectTimer, tmp);
    }
    else
    {   
        if(cli->checkConnected(fd))
        {
            uint8_t mod = cli->mod_;
            if (mod == ConType::ConType_client_gate1 ||
                mod == ConType::ConType_client_gate2 ||
                mod == ConType::ConType_client_gate3 ||
                mod == ConType::ConType_client_gate4 ||
                mod == ConType::ConType_game_client)
            {
                cli->loop_->cleanQueue();
            }

            std::string name = cli->getName();

            cli->fd_ = fd;
            cli->sessionId_ = gClienAutoIncretId++;

            cli->con_ = new TcpConnecter(fd, cli->sessionId_, cli->loop_);
            TcpConnecter* con = cli->con_;

            con->setMod(mod);
            con->setLoopName(name);
            con->setIpAndPort(cli->ip_.data(), cli->port_);
            con->getChannel()->setEvent(EPOLLIN);
            con->setCloseCb(std::bind(&Client::serverClose, cli, std::placeholders::_1, std::placeholders::_2));
            con->init();

            if(name == "game_server")
            {
                gameDumpFlag_ = false;
            }

            
            if (mod == ConType::ConType_game_client)
            {
                Task t;
                t.opt_ = ConType::ConType_game_client;
                t.connect_ = true;
                std::unique_lock<std::mutex> lk(gMutex);
                gQueue.emplace(std::move(t));
                lk.unlock();
                gCondVar.notify_one();
            }
            
            cli->status_ = true;

            logInfo("------------------------------connect %s success id:%llu idx:%d------------------------------", name.data(), con->getSessionId(), mod);
        }
        else
        {
            close(fd);
            Args *tmp = (Args *)malloc(sizeof(Args));
            tmp->obj_ = args->obj_;
            gTimer.add(1, &Client::staticConnectTimer, tmp);

        }

    }

}

const char *Client::getName(bool clientName)
{
    const char *info = "unknow";
    if (mod_ == ConType::ConType_game_client)
    {
        info = "master_server";
        if (clientName)
        {
            info = "game_client";
        }
    }
    else if (mod_ == ConType::ConType_log_client)
    {
        info = "log_server";
        if (clientName)
        {
            info = "log_client";
        }
    }
    else if (mod_ == ConType::ConType_client_gate1)
    {
        info = "game_server";
        if (clientName)
        {
            info = "gate_client1";
        }
    }
    else if (mod_ == ConType::ConType_client_gate2)
    {
        info = "game_server";
        if (clientName)
        {
            info = "gate_client2";
        }
    }
    else if (mod_ == ConType::ConType_client_gate3)
    {
        info = "game_server";
        if (clientName)
        {
            info = "gate_client3";
        }
    }
    else if (mod_ == ConType::ConType_client_gate4)
    {
        info = "game_server";
        if (clientName)
        {
            info = "gate_client4";
        }
    }
    else if (mod_ == ConType::ConType_http_client)
    {
        info = "http_server";
        if (clientName)
        {
            info = "http_client";
        }
    }
    else
    {
        info = "db_server";
        if (clientName)
        {
            info = "db_client";
        }
    }
    return info;
}


bool Client::checkPortUsed()
{
    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) 
	{
        return false;
    }

    int opt = 1;
    if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0) 
	{
        close(sockfd);
        return false;
    }


    struct sockaddr_in address;
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = inet_addr(ip_.data()); 
    address.sin_port = htons(port_); 

    if (bind(sockfd, (struct sockaddr *)&address, sizeof(address)) < 0) 
	{
        close(sockfd);
        return true;
    }

    close(sockfd);
    return false;
}


void Client::serverClose(uint64_t sessionId, bool notice)
{
    if (quit_.load())
    {
        logInfo("服务器已关闭不在连接");
        return;
    }

    status_ = false;

    Channel* ch = con_->getChannel();
    loop_->updateEvent(ch, EPOLL_CTL_DEL);
    close(fd_);

    delete con_;
    con_ = nullptr;

    if (mod_ == ConType::ConType_client_gate1 ||
        mod_ == ConType::ConType_client_gate2 ||
        mod_ == ConType::ConType_client_gate3 ||
        mod_ == ConType::ConType_client_gate4)
    {
        Task t;
        t.opt_ = mod_;
        t.gameClose_ = true;
        std::unique_lock<std::mutex> lk(gMutex);
        gQueue.emplace(std::move(t));
        lk.unlock();
        gCondVar.notify_one();            
    }


    Args *args = (Args *)malloc(sizeof(Args));
    args->obj_ = this;
    gTimer.add(1, &Client::staticConnectTimer, args);

    logInfo("--------------------------dis connect %s id:%llu----------------------", getName(), sessionId);

}

void Client::sendMessage2Server(Task &t)
{
    // logInfo("sendMessage2Server %d", t.len_);
    if (!loop_)
    {
        if (t.data_)
        {
            free(t.data_);
        }
        return;
    }

    if (mod_ == ConType::ConType_client_gate1 ||
        mod_ == ConType::ConType_client_gate2 ||
        mod_ == ConType::ConType_client_gate3 ||
        mod_ == ConType::ConType_client_gate4)
    {
        if (status_.load())
        {
            //logInfo("发消息给游戏服务器");
            loop_->addMessage(t);
            loop_->weakUp();
        }
        else
        {   
            if (t.data_)
            {
                free(t.data_);
            }
        }
    }
    else
    {
        if (status_.load())
        {
            loop_->addMessage(t);
            loop_->weakUp();
        }
    }
}



