个人开源游戏服务器框架c++底层.lua逻辑.只在linux系统运行

1:主线程负责所有的业务逻辑.

2:有一个线程单独负责客户端的连接

3:可选的work线程.n个负责和客户端的socket消息读取和发送.当n==0的话连接线程和消息处理的线程将是同一个

4:实现了c++和lua的通信模块.同一个c++接口,lua调用该接口和c++调用该接口是一致的,不需要其他的机制

5:实现了log日志模块.有个线程单独负责将日志buff写入文件

6:协议采用protobuff3.0版本.协议的编码和解码都是在c++中实现的.lua代码没有实现编解码

7:lua中的热更新指令已经实现.

8:支持vscode的lua断点调试.需要在vscdoe安装luapand

9:架构为game进程,db进程,log进程,gate进程
gate:客户端连接它,使用的是websocket
game:游戏的主
log:处理流水日志
bd:负责数据存储

10:网络层使用的都是基本的socket api构建,多线程模式

11:敏感词过滤已经实现

12:基本上的所有的东西已经完成,可以做项目使用

12.1 normal里面是开服的一些脚本

13:基本测试(模拟正式的游戏登入流程)
协议格式
// 请求登入认证 
message ReqLoginAuth
{
    sint32 serverId=1; // 当前服务器id
    string account=2; // 账号
    string password=3; // 密码
    string pf=4; // 平台名字
    sint32 fromServerId=5; // 初始服务器id
}

// 登入认证返回 
message ResLoginAuth
{
    sint32 code=1;
}

// 查询玩家 
message ReqSelectPlayer
{
}

// 查询玩家返回 
message ResSelectPlayer
{
    uint64 pid=1; // 玩家id
    sint32 code=2; 
}


// 请求创建玩家 
message ReqCreatePlayer
{
    sint32 sex=1; // 1:男 2:女
    bytes name=2; // 名字
}

// 创建玩家返回 
message ResCreatePlayer
{
    sint32 sex=1; // 1:男 2:女
    bytes name=2; // 玩家名字
    uint64 pid=3; // 玩家id
    sint32 code=4; 
}

// 请求进入游戏 
message ReqEnterGame
{
    uint64 pid=1; // 玩家id 
}

// 请求进入游戏返回 
message ResEnterGame
{
    sint32 code=1; // 进入游戏结果
}

简单的性能测试
服务器:8c32g
客户端:8c32g
流程:
启动各个进程,客户端启动10000个线程去连接网关.之后消息转发给出game进程处理,game的消息会转给db处理在回来给game在返回给gate在到客户端
日志打印显示:10000个连接处理完上面的协议.大概需要35秒.每秒约285个.走完一个完整的服务器登录流程

个人qq:1727198740.欢迎交流
