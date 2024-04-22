

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

std::unordered_map<uint8_t, Client *> gServerClients;
std::mutex gClientMutex;
uint8_t gClientIdx = 1;

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

    sleep(1);
    if (loop_)
    {
        // logInfo("quitClientquitClientquitClient");
        loop_->quit_.store(true, std::memory_order_relaxed);
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
    Args *args = (Args *)je_malloc(sizeof(Args));
    args->obj_ = this;
    args->first_ = true;

    Client::staticConnectTimer(args);
}

void Client::staticConnectTimer(Args *args)
{
    Client *cli = (Client *)args->obj_;
    uint8_t mod = cli->mod_;
    cli->fd_ = socket(AF_INET, SOCK_STREAM, 0);
    int fd = cli->fd_;
    if (fd <= 0)
    {
        if (args->first_)
        {
            logQuit("staticConnectTimer socket err %d %d", mod, errno);
            _exit(0);
        }

        return;
    }

    fcntl(fd, F_SETFL, fcntl(fd, F_GETFL, 0) | O_NONBLOCK);

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(struct sockaddr_in));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(cli->port_);
    addr.sin_addr.s_addr = inet_addr(cli->ip_.data());

    int ret = connect(fd, (struct sockaddr *)&addr, sizeof(struct sockaddr));

    cli->sessionId_ = gClienAutoIncretId++;
    cli->con_ = new TcpConnecter(cli->fd_, cli->sessionId_, cli->loop_);
    cli->con_->setMod(cli->mod_);
    cli->con_->setIpAndPort(cli->ip_.data(), cli->port_);

    // logInfo("ssssssss %d %d %s %d %d",args->first_,ret,cli->ip_.data(),cli->port_,cli->mod_);
    if (args->first_ && ret == 0)
    {
        cli->con_->init();
        cli->con_->setCloseCb(std::bind(&Client::serverClose, cli, std::placeholders::_1));
        logInfo("------------------------------first connect %s success------------------------------", cli->getName());
    }
    else
    {
        cli->con_->initClient(cli);
    }

    if (args->first_)
    {
        cli->ioThread_ = std::move(std::thread([cli]()
                                               { cli->loop_->startLoop(cli->getName(true)); }));
    }

    je_free(args);
    args = nullptr;
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

void Client::conncetCallBack()
{

    int err = 0;
    socklen_t len = sizeof(err);
    getsockopt(fd_, SOL_SOCKET, SO_ERROR, &err, &len);

    if (err == 0)
    {
        bool ok = true;

        if ((gParseConfig.masterPort_ == 0 || gParseConfig.masterIp_.empty()) && mod_ == ConType::ConType_game_client)
        {
            ok = false;
        }

        if (ok)
        {
            con_->getChannel()->setEvent(EPOLLIN);
            loop_->updateEvent(con_->getChannel(), 3);
            con_->init();
            con_->setCloseCb(std::bind(&Client::serverClose, this, std::placeholders::_1));
            if (mod_ == ConType::ConType_client_gate1 ||
                mod_ == ConType::ConType_client_gate2 ||
                mod_ == ConType::ConType_client_gate3 ||
                mod_ == ConType::ConType_client_gate4 ||
                mod_ == ConType::ConType_game_client)
            {
                loop_->cleanQueue();
            }

            loop_->weakUp();
            logInfo("------------------------------connect %s success------------------------------", getName());
            status_.store(true, std::memory_order_relaxed);

            if (mod_ == ConType::ConType_game_client)
            {
                Task t;
                t.opt_ = ConType::ConType_game_client;
                t.connect_ = true;
                std::unique_lock<std::mutex> lk(gMutex);
                gQueue.push(std::move(t));
                lk.unlock();
                gCondVar.notify_one();
            }
        }
        else
        {
            serverClose();
        }
    }
    else
    {
        serverClose();
    }
}

void Client::serverClose(uint64_t sessionId)
{
    if (sessionId > 0)
    {
        status_.store(false, std::memory_order_relaxed);
        Task t;
        t.opt_ = mod_;
        if (mod_ == ConType::ConType_client_gate1 ||
            mod_ == ConType::ConType_client_gate2 ||
            mod_ == ConType::ConType_client_gate3 ||
            mod_ == ConType::ConType_client_gate4)
        {
            t.gameClose_ = true;
        }

        std::unique_lock<std::mutex> lk(gMutex);
        gQueue.emplace(std::move(t));
        lk.unlock();
        gCondVar.notify_one();

        logInfo("--------------------------dis connect %s ----------------------", getName());
    }

    // logInfo("serverCloseserverClose %d %d", mod_, quit_);
    Channel *ch = con_->getChannel();
    if (ch)
    {
        loop_->updateEvent(ch, 2);
    }

    close(con_->getFd());

    delete con_;
    con_ = nullptr;

    if (quit_)
    {
        // logInfo("serverCloseserverClose11111111111 %d %d", mod_, quit_);
        return;
    }

    sleep(1);

    Args *args = (Args *)je_malloc(sizeof(Args));
    args->obj_ = this;
    args->first_ = false;
    staticConnectTimer(args);
}

void Client::sendMessage2Server(Task &t)
{
    // logInfo("sendMessage2Server %d", t.len_);
    if (!loop_)
    {
        if (t.data_)
        {
            je_free(t.data_);
        }
        return;
    }

    if (mod_ == ConType::ConType_client_gate1 ||
        mod_ == ConType::ConType_client_gate2 ||
        mod_ == ConType::ConType_client_gate3 ||
        mod_ == ConType::ConType_client_gate4)
    {
        if (status_.load(std::memory_order_relaxed))
        {
            loop_->addMessage(t);
            loop_->weakUp();
        }
        else
        {
            if (t.data_)
            {
                je_free(t.data_);
            }
        }
    }
    else
    {
        if (status_)
        {
            loop_->addMessage(t);
            loop_->weakUp();
        }
    }
}

uint8_t Client::getClientIdx(uint8_t idx)
{
    if (idx == 1)
    {
        return ConType::ConType_client_gate1;
    }
    else if (idx == 2)
    {
        return ConType::ConType_client_gate2;
    }
    else if (idx == 3)
    {
        return ConType::ConType_client_gate3;
    }
    else if (idx == 4)
    {
        return ConType::ConType_client_gate4;
    }
    return ConType::ConType_client_gate1;
}

Client *Client::getClient()
{
    std::unique_lock<std::mutex> lk(gClientMutex);
    uint8_t cidx = Client::getClientIdx(gClientIdx++);
    if (gClientIdx > 4)
    {
        gClientIdx = 1;
    }

    Client *cl = gServerClients[cidx];
    lk.unlock();
    return cl;
}