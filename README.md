个人开源游戏服务器框架c++底层.lua逻辑.只在linux系统运行(也支持websocket协议)

1:主线程负责所有的业务逻辑.

2:有一个线程单独负责客户端的连接

3:可选的work线程.n个负责和客户端的socket消息读取和发送.当n==0的话连接线程和消息处理的线程将是同一个

4:实现了log日志模块.有个线程单独负责将日志buff写入文件

5:协议采用protobuff3.0版本.协议的编码和解码都是在c++中实现的.lua代码没有实现编解码,详见src\gameServer\src\codec

6:支持vscode的lua断点调试.需要在vscdoe安装luahelper

7支持c++代码断点调试

8:架构为game进程,db进程,gate进程
gate:客户端连接它,websocket,也可以是普通的tcp服务器
game:游戏的主体
db:负责数据存储,缓存

10:网络层使用的都是基本的socket api构建,多线程模式

12.1 normal里面是开服的一些脚本

13:基本测试(模拟正式的游戏登入流程)
协议格式


syntax = "proto3";

  // 请求登入认证 
message ReqLoginAuth
{
    uint32 serverId     = 1;  // 当前服务器id
    string account      = 2;  // 账号
    string password     = 3;  // 密码
    string pf           = 4;  // 平台名字
    uint32 fromServerId = 5;  // 初始服务器id
}

  // 登入认证返回 
message ResLoginAuth
{
    uint32 code = 1;
}

  // 查询玩家 
message ReqSelectPlayer
{
}

  // 查询玩家返回 
message ResSelectPlayer
{
    uint64 pid  = 1;  // 玩家id
    uint32 code = 2;
}


  // 请求创建玩家 
message ReqCreatePlayer
{
    uint32 sex  = 1;  // 1:男 2:女
    string name = 2;  // 名字
}

  // 创建玩家返回 
message ResCreatePlayer
{
    uint32 sex  = 1;  // 1:男 2:女
    string name = 2;  // 玩家名字
    uint64 pid  = 3;  // 玩家id
    uint32 code = 4;
}

  // 请求进入游戏 
message ReqEnterGame
{
    uint64 pid = 1;  // 玩家id 
}


个人qq:1727198740.欢迎交流
