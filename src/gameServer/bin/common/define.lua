local define = {}

-- 客户端奖励提示定义
define.rewardTypeDefine = {
    notshow       = 0, -- 不显示
    show          = 1, -- 正常显示
    recruit       = 2, -- 招募
    playerUpLevel = 3, -- 玩家升级
    collect       = 4, -- 采集
    fightEnd      = 5, -- 战斗完毕
    eightSign     = 6, -- 八日签到
    towerRd       = 7 -- 蜃楼选择奖励
}

-- 玩家功能模块id定义
define.playerModuleDefine = {
    bag       = 1, -- 玩家背包
    currency  = 2, -- 货币
    hero      = 3, -- 英雄模块
    workshop  = 4, -- 工坊
    furniture = 5, -- 家具
    gacha     = 6, -- 招募
    product   = 7, -- 装备制造模块
    adventure = 8, -- 冒险

    task             = 9,  -- 任务
    store            = 10, -- 商店
    rating           = 11, -- 评价
    functionopen     = 12, -- 功能开启
    mail             = 13, -- 邮件系统
    chat             = 14, -- 聊天系统
    common           = 16, -- 公共系统, 放些杂七杂八的功能
    activity         = 17, -- 运营活动数据
    friend           = 18, -- 好友数据
    carriage         = 19, -- 马车系统
    tower            = 20, -- 蜃楼(爬塔)
    equipHistory     = 21, -- 装备图纸历史数据
    itemHistory      = 22, -- 物品历史数据
    cacheSpace       = 23, -- 缓存空间数据
    charge           = 24, -- 充值数据
    historyCharge    = 25, -- 历史充值订单数据
    npc              = 26, -- npc数据
    boss             = 27, -- boss
    firstChargeGift  = 28, -- 首冲礼包
    cumulativeCharge = 29, -- 累计充值
    guild            = 30, -- 工会数据
    
    
}

-- 全局功能模块id定义
define.globalModuleDefine = {
    mail   = 1, -- 邮件模块
    chat   = 2, -- 聊天,
    guild  = 3, -- 公会
    friend = 4, -- 好友
    charge = 5, -- 充值
    guildLog = 6, -- 公会日志
    guildOther = 7, -- 公会杂项数据
}

-- 临时全局功能模块id定义
define.globalTmpModuleDefine = {
    mail = 1 -- 邮件模块
}

-- 玩家临时模块数据id定义,不会写入数据库,玩家下线就删除
define.playerTmpDataIdDefine = {
    bag = 1, -- 背包
    npc = 2 -- 特殊npc(物品/装备)
}

-- 物品类型
define.itemType = {
    item      = 1, -- 普通道具               可堆叠
    equip     = 2, -- 装备                  不可堆叠
    currency  = 3, -- 货币               可堆叠
    furniture = 4, -- 家具              不可堆叠
    hero      = 5, -- 英雄                   不可堆叠

    carriage = 1000 -- 马车类型(实际不是物品类型,是属于一个功能的.放在这了是为了统一)
}

-- 物品子类型
define.itemSubType = {
    currency       = 1, -- 1.货币
    normalMaterial = 2, -- 2.基础材料
    rareMaterial   = 3, -- 3.稀有材料
    spMaterial     = 4, -- 4.特殊材料
    normalFormula  = 5, -- 5.图通图纸
    rareFormula    = 6, -- 6.稀有图纸
    fragment       = 7, -- 7.英雄碎片
    studyActive    = 8, -- 英雄课程激活道具
    baijian         = 9 -- 摆件碎片
}

-- 货币id
define.currencyType = {
    none          = 0,
    gold          = 1,  -- 通币
    jade          = 2,  -- 仙玉
    jadeYin       = 3,  -- 琼瑜
    goodWill      = 4,  -- 善意
    sepreneWall   = 5,  -- 清幽壁
    ziFuXiang     = 6,  -- 紫府香
    activeColn    = 7,  -- 活动币(暂用名)
    ratingExp     = 8,  -- 评价经验
    furnitures    = 9,  -- 万能摆件碎片
    bossTili      = 10, -- 经营验证/boss体力
    towerCurrency = 11, -- 蜃楼货币(以物换物的消耗)
    towerScore    = 12, -- 蜃楼积分
    formulaScroll = 13, -- 图纸书籍卷
    guild         = 14, -- 公会币

    zhizaoAchiScore   = 50, -- 制造成就积分
    jingyingAchiScore = 51, -- 经营成就积分
    maoxianAchiScore  = 52, -- 冒险成就积分
    gelouAchiScore    = 53, -- 阁楼成就积分
    max               = 100 -- 最大值
}
-- 工坊效果
define.MAP_TYPE = {
    FILOW_DEVEL          = 1,  -- 1	客流开拓
    RISING_REPUT         = 2,  -- 2	声誉鹊起
    BARGAIN              = 3,  -- 3	讨价还价
    SMILING              = 4,  -- 4	微笑服务
    LION_OPEN            = 5,  -- 5	狮子开口
    PACK_PROMOTION       = 6,  -- 6	打包促销
    TEMPERED_STEEL       = 7,  -- 7	百炼成钢
    UNCANNY_WORKMANGSHIP = 8,  -- 8	鬼斧神工
    FINE_CRAF            = 9,  -- 9	精工细作
    UNIQUE_INGENUIY      = 10, -- 10	匠心独运
    CAREFULLY            = 11, -- 11	精雕细琢
    INGENIOUS            = 12, -- 12	巧夺天工
    SPEED_UP             = 13, -- 13	快马加鞭
    SEARCH_EXHAUSTIVELY  = 14, -- 14	搜罗殚尽
    WATER_FIRE           = 15, -- 15	水火既济
    NINE_TURN            = 16 -- 16	九转丹成
}

-- 评价效果枚举：
define.ratingEfffect = {
    productEqu  = 1, -- 1.解锁指定阶数指定类型装备（1，大类id（1武器、2防具、3饰品）, 阶数）
    formula     = 2, -- 2.解锁指定格店铺的扩建(2,店铺数)
    productSlot = 3, -- 3.解锁指定铸造槽位的解锁(3,槽位id)
    func        = 4, -- 4.指定功能解锁（4,                         开放ID（对应functionOpen的id))
    formulaNum = 5, -- 5.指定类型家具数量（5,类型id(1货架、2资源）,数量）
    formulaLevel = 6, -- 6.指定类型家具最高等级（6,类型id(1货架、2资源）,最高等级）
    carriageSlot   = 7, -- 7.指定数量马车槽位（7, 槽位id）
    workshop       = 8, -- 8.指定工坊解锁（8类型, 1.采集工坊  2.制造工坊 3, 经营工坊 4.炼丹工坊）(新增)
    workshopRoomId = 9, -- 9.提升四大工坊房间等级上限（9类型，可以达到的等级上限）(新增)
    advCollTeam    = 10 -- 10.采集队伍解锁（达到条件自动增加采集队伍数量）（10类型，累加数量）
}

define.battlePointType = {
    none       = 0,
    checkPoint = 1,
    progress   = 2,
    collect    = 3,
    boss       = 4,
    material   = 5,
    treasure   = 6
}

define.__ADDITION_TYPE = {

    MAKE_TIME_DECR         = 1,  -- 铸造所需时间减少
    PRICE_ADDITION         = 2,  -- 装备售卖价值增加
    ROLE_EXP_ADDITION      = 3,  -- 装备售卖经验增加
    WORKER_EXP_ADDITION    = 4,  -- 装备收取工匠经验增加
    MAKE_QUALITY_INCR      = 5,  -- 高品质铸造概率增加
    RISE_ENERGY_DECR       = 6,  -- 涨价需求善意减少
    DISCOUNT_ENERGY_INCR   = 7,  -- 降价获得善意增加
    RISE_RATE_INCR         = 8,  -- 涨价的价值倍率的增加
    DISCOUNT_RATE_DECR     = 9,  -- 降价的价值倍率的增加
    SPEED_UP_ENERGY_DECR   = 10, -- 加速消耗的善意减少比例
    MAKE_DOUDLE            = 11, -- 增加双重获得概率
    MAKE_MAT_DECR          = 12, -- 铸造材料减少
    ENCHANT_SUCC_RATE_INCR = 13, -- 附魔成功率增加
    ENCHANT__PRICE_INCR    = 14 -- 附魔后的装备价值增加
}

-- 装备品质
define.equipQuality = {
    white  = 1, -- 1.白
    green  = 2, -- 2.绿
    blue   = 3, -- 3.蓝
    purple = 4, -- 4.紫
    orange = 5 -- 5.橙
}

-- 装备品级
define.equipStage = {
    normal = 1, -- 普通品级
    rare   = 2 -- 稀有品级
}


define.equipClass = {
    weapon     = 1, -- 武器
    armor      = 2, -- 防具
    decoration = 3 -- 装饰
}

define.talentName = {
    arrange = "talentArrange"
}
-- 装备部位
define.equiportionType = {
    [1]  = define.equipClass.weapon,     -- 1剑
    [2]  = define.equipClass.weapon,     -- 2刀
    [3]  = define.equipClass.weapon,     -- 3匕首
    [4]  = define.equipClass.weapon,     -- 4锤
    [5]  = define.equipClass.weapon,     -- 5枪
    [6]  = define.equipClass.weapon,     -- 6弓
    [7]  = define.equipClass.weapon,     -- 7琴
    [8]  = define.equipClass.weapon,     -- 8扇
    [9]  = define.equipClass.weapon,     -- 9暗器
    [10] = define.equipClass.weapon,     -- 10弩
    [11] = define.equipClass.armor,      -- 11重甲
    [12] = define.equipClass.armor,      -- 12皮甲
    [13] = define.equipClass.armor,      -- 13素衣
    [14] = define.equipClass.armor,      -- 14头盔
    [15] = define.equipClass.armor,      -- 15面具
    [16] = define.equipClass.armor,      -- 15面具
    [17] = define.equipClass.armor,      -- 17护臂
    [18] = define.equipClass.armor,      -- 18护腕
    [19] = define.equipClass.armor,      -- 19重靴
    [20] = define.equipClass.armor,      -- 20轻履
    [21] = define.equipClass.decoration, -- 21术法
    [22] = define.equipClass.decoration, -- 22香囊
    [23] = define.equipClass.decoration, -- 23阵旗
    [24] = define.equipClass.decoration, -- 24护坠
    [25] = define.equipClass.decoration, -- 25戒指
    [26] = define.equipClass.decoration -- 26玉佩
}

-- 任务累计方式
define.taskValType = {
    add   = 1, -- 累计
    cover = 2 -- 覆盖
}

define.taskType = {
    makeEquip = 1, -- 制造x件凡品装备 [品质，大类，部位，装备id]，【代表品质），大类1.武器 2.饰品 3.防具，部位.1.武器 2.服饰, 3.手部 4.鞋子，5.头部 6.配饰 装备idxxxxx】

    forgeCnt       = 2, -- 炼造xx次 【道具id】完成
    takonEquip     = 3, -- 穿戴装备[品质，大类，部位，装备id]，【代表品质），大类1.武器 2.饰品 3.防具，部位.1.武器 2.服饰, 3.手部 4.鞋子，5.头部 6.配饰 装备idxxxxx】
    makeEquipState = 4, -- 制造x件x阶的装备

    makeEquipStateQuality = 5, -- 制造x件x阶x品质的装备

    makeEquipQuality1  = 6,  -- 	制作剑类武器造出A品质
    makeEquipQuality2  = 7,  -- 	制作刀类武器造出A品质
    makeEquipQuality3  = 8,  -- 	制作匕首类武器造出A品质质
    makeEquipQuality4  = 9,  -- 	制作锤类武器造出A品质
    makeEquipQuality5  = 10, -- 制作枪类武器造出A品质
    makeEquipQuality6  = 11, -- 制作弓类武器造出A品质
    makeEquipQuality7  = 12, -- 制作琴类武器造出A品质
    makeEquipQuality8  = 13, -- 制作扇类武器造出A品质
    makeEquipQuality9  = 14, -- 制作暗器类武器造出A品质
    makeEquipQuality10 = 15, -- 制作弩类武器造出A品质
    makeEquipQuality11 = 16, -- 制作重甲类武器造出A品质
    makeEquipQuality12 = 17, -- 制作皮甲类武器造出A品质
    makeEquipQuality13 = 18, -- 制作素衣类武器造出A品质
    makeEquipQuality14 = 19, -- 制作头盔类武器造出A品质
    makeEquipQuality15 = 20, -- 制作面具类武器造出A品质
    makeEquipQuality16 = 21, -- 制作冠帽类武器造出A品质
    makeEquipQuality17 = 22, -- 制作护臂类武器造出A品质
    makeEquipQuality18 = 23, -- 制作护腕类武器造出A品质
    makeEquipQuality19 = 24, -- 制作重靴类武器造出A品质
    makeEquipQuality20 = 25, -- 制作轻履类武器造出A品质
    makeEquipQuality21 = 26, -- 制作术法类武器造出A品质
    makeEquipQuality22 = 27, -- 制作香囊类武器造出A品质
    makeEquipQuality23 = 28, -- 制作阵旗类武器造出A品质
    makeEquipQuality24 = 29, -- 制作护坠类武器造出A品质
    makeEquipQuality25 = 30, -- 制作戒指类武器造出A品质
    makeEquipQuality26 = 31, -- 制作玉佩类武器造出A品质

    makeForlumaId = 32, -- 制造指定图纸id



    collectCnt  = 100, -- 进行x次采集
    businessCnt = 101, -- 进行x次有无商行行为

    sellEquipCnt       = 102, -- 出售x件装备[品质，大类，部位，装备id]，【代表品质（0.绝品., 1.凡品），大类1.武器 2.饰品 3.防具，部位.1.武器 2.服饰, 3.手部 4.鞋子，5.头部 6.配饰 装备idxxxxx】
    raiseOrDiscountCnt = 103, -- 进行x次涨价 或降价0代表涨价 1.代表降价

    talk = 104, -- 进行x次闲聊

    equipRecommendation = 105, -- 进行x次推荐装备
    sale                = 106, -- 销售额累积达到xx

    workShopAddCnt  = 107, -- 工坊内上阵员工达到xx人
    lockWorkShopCnt = 108, -- 解锁x工坊    当为此type时，1为采集工坊 2为建造工坊 3为经营工坊 4为炼丹工坊
    planCollectCnt  = 109, -- 安排x个采集队
    playerLv        = 110, -- 评价(玩家)等级达到xx级别
    slotCnt         = 111, -- 拥有x个制造槽位

    comTalkAndRise = 112, -- 完成x次闲聊，进行x次涨价 混合任务
    comDisAndSell  = 113, -- 完成x次降价，进行x次销售    混合任务

    furnitureCnt       = 114, -- 拥有x个xx家具   此时特殊参数为家具id
    furnitureLevel     = 115, -- xx个xx家具达到xx级 此时特殊参数为【家具id，等级】
    extendShop         = 116, -- 店铺扩建至xx级
    raiseAndSell       = 117, -- 涨价出售x次(非复合任务)
    disAndSell         = 118, -- 降价出售x次(非复合任务)
    furnitureLevelType = 119, -- 拥有x个x级别x种类的家具	【等级,   种类furniture的type表】
    workshopTianfuDian = 120, -- 工坊已经分配点数达到xx点 动态变化的, 如果已领取的就不处理
    sellFixEquipCnt    = 121, -- 出售x件固定装备 装备表的belong字段
    checkpoint         = 200, -- 通关xx
    upHeroLevelOrStep  = 201, -- 进行x次英雄升级或进阶x次

    upEquipLevel = 202, -- 对装备升级x次

       upTalentLv              = 203, -- 进行x次天赋升级
       costTili                = 204, -- 消耗x点体力
       heroAllLv               = 205, -- 累积xx个角色达到xx级    此时特殊参数为等级
       getEquipLvCnt           = 206, -- 拥有xx个xx级别装备 此时特殊参数为等级
    -- mainCheckpoint          = 207, -- 通关第x章主线
       mainCheckpointType      = 208, -- 累积挑战xx种类关卡x次	【关卡种类 battlepoint的type】
       mainCheckpointBox       = 209, -- 累积获取关卡内宝箱x个
       collectTime             = 210, -- 累积采集时长达到xx小时
       heroMingzuoLv           = 211, -- 累积x个角色命座升到x级/心海
       heroPuGongLv            = 212, -- 累积x名角色的普攻升到x级
       heroZhanjiLv            = 213, -- 累积x名角色的战技升到x级
       heroBeiDongLv           = 214, -- 累积x名角色的被动技能升到x级
       heroJingyingLv          = 215, -- 累积x名角色解锁经营被动技能
       mainCheckpointFormation = 216, -- 主线队伍x上阵y个英雄

    login    = 300, -- 每日登录游戏
    recruit  = 301, -- 进行x次招募
    accLogin = 304, -- 累积登录x

    activeEquip1  = 310, -- 	    激活剑类的A图纸
    activeEquip2  = 311, -- 	    激活刀类的A图纸
    activeEquip3  = 312, -- 	    激活匕首类的A图纸
    activeEquip4  = 313, -- 	    激活锤类的A图纸
    activeEquip5  = 314, -- 	激活枪类的A图纸
    activeEquip6  = 315, -- 	激活弓类的A图纸
    activeEquip7  = 316, -- 	激活琴类的A图纸
    activeEquip8  = 317, -- 	激活扇类的A图纸
    activeEquip9  = 318, -- 	激活暗器类的A图纸
    activeEquip10 = 319, -- 	激活弩类的A图纸
    activeEquip11 = 320, -- 	激活重甲类的A图纸
    activeEquip12 = 321, -- 	激活皮甲类的A图纸
    activeEquip13 = 322, -- 	激活素衣类的A图纸
    activeEquip14 = 323, -- 	激活头盔类的A图纸
    activeEquip15 = 324, -- 	激活面具类的A图纸
    activeEquip16 = 325, -- 	激活冠帽类的A图纸
    activeEquip17 = 326, -- 	激活护臂类的A图纸
    activeEquip18 = 327, -- 	激活护腕类的A图纸
    activeEquip19 = 328, -- 	激活重靴类的A图纸
    activeEquip20 = 329, -- 	激活轻履类的A图纸
    activeEquip21 = 330, -- 	激活术法类的A图纸
    activeEquip22 = 331, -- 	激活香囊类的A图纸
    activeEquip23 = 332, -- 	激活阵盘类的A图纸
    activeEquip24 = 333, -- 	激活玉佩类的A图纸
    activeEquip25 = 334, -- 	激活护像类的A图纸
    activeEquip26 = 335, -- 	激活戒指类的A图纸

    equipProcess1  = 340, -- 	剑类图纸的某装备进度达到A
    equipProcess2  = 341, -- 	刀类图纸的某装备进度达到A
    equipProcess3  = 342, -- 	匕首类图纸的某装备进度达到A
    equipProcess4  = 343, -- 	锤类图纸的某装备进度达到A
    equipProcess5  = 344, -- 	枪类图纸的某装备进度达到A
    equipProcess6  = 345, -- 	弓类图纸的某装备进度达到A
    equipProcess7  = 346, -- 	琴类图纸的某装备进度达到A
    equipProcess8  = 347, -- 	扇类图纸的某装备进度达到A
    equipProcess9  = 348, -- 	暗器类图纸的某装备进度达到A
    equipProcess10 = 349, -- 	弩类图纸的某装备进度达到A
    equipProcess11 = 350, -- 	重甲类图纸的某装备进度达到A
    equipProcess12 = 351, -- 	皮甲类图纸的某装备进度达到A
    equipProcess13 = 352, -- 	素衣类图纸的某装备进度达到A
    equipProcess14 = 353, -- 	头盔类图纸的某装备进度达到A
    equipProcess15 = 354, -- 	面具类图纸的某装备进度达到A
    equipProcess16 = 355, -- 	冠帽类图纸的某装备进度达到A
    equipProcess17 = 356, -- 	护臂类图纸的某装备进度达到A
    equipProcess18 = 357, -- 	护腕类图纸的某装备进度达到A
    equipProcess19 = 358, -- 	重靴类图纸的某装备进度达到A
    equipProcess20 = 359, -- 	轻履类图纸的某装备进度达到A
    equipProcess21 = 360, -- 	术法类图纸的某装备进度达到A
    equipProcess22 = 361, -- 	香囊类图纸的某装备进度达到A
    equipProcess23 = 362, -- 	阵盘类图纸的某装备进度达到A
    equipProcess24 = 363, -- 	玉佩类图纸的某装备进度达到A
    equipProcess25 = 364, -- 	护像类图纸的某装备进度达到A
    equipProcess26 = 365, -- 	戒指类图纸的某装备进度达到A

    mainCheckpointRd = 400, -- 章节奖励    为此type时，需要判断任务范围【任务id1，任务idn】

    dailyTaskCnt  = 401, -- 日常任务总进度奖励  为此type时，需要判断任务范围【任务id1，任务idn】
    achiPageCount = 402 -- 每页签总成就进度 cond 未货币id

}

-- 奖励状态
define.taskRewardDef = {
    noRecv = 0, -- 未领取
    recv   = 1 -- 已领取
}

-- 解锁状态
define.lockStatusDef = {
    lock   = 0, -- 未解锁
    unlock = 1 -- 已解锁
}

-- 解锁条件
define.openLockType = {
    defalut       = 0, -- 默认无条件解锁
    level         = 1, -- 玩家等级
    newPersonTask = 2, -- 新手任务
    checkpoint    = 3, -- 主线关卡
    hero          = 4 -- 获取英雄
}

define.taskTypeDef = {
    newPerson  = 1, -- 新手任务
    daily      = 2, -- 每日任务
    chapter    = 3, -- 章节任务
    tiangongpu = 4, -- 天工谱

    achi = 6 -- 成就
}

-- 功能开启定义
define.functionOpen = {
    maoxian           = 1001, -- 冒险
    bank              = 1002, -- 有无商行
    mail              = 1004, -- 邮件
    make              = 1005, -- 装备制造
-- funitureUp        = 1006, -- 家具升级
-- funitureGet       = 1007, -- 家具收纳
    riseOrDis         = 1008, -- 涨价or降价
    qianChengHuiMeng  = 1009, -- 前尘回梦
    dailyAndNewperson = 1010, -- 日常任务与新手任务
    sign              = 1011, -- 签到
    hero              = 1012, -- 英雄系统
    workshop          = 1013, -- 工坊
    recurit           = 1014, -- 招募
    shoppingMall      = 1015, -- 商城
    fuben             = 1016, -- 副本
    mijing            = 1017, -- 秘境
    houShan           = 1018, -- 后山
    sheJi             = 1019, -- 设计
    chapter           = 1020, -- 章节任务
    newperson         = 1021, -- 新手任务
    daily             = 1022, -- 日常任务
    playerInfo        = 1023, -- 玩家信息
    guke              = 1024, -- 顾客
    team              = 1025, -- 组队
    extendMake        = 1026, -- 扩展制造
    onekeyCaiji       = 1027, -- 一键采集
    unlockJianzhu     = 1028, -- 解锁建筑
    tianGongPu        = 1029, -- 天工谱
    recruit           = 1030, -- 招募
    tower             = 1031, -- 爬塔
    boss              = 1032, -- boss/经营验证
    achi              = 1033, -- 成就
    study             = 1034, -- 英雄学习
    guild             = 1035, -- 公会
    eightSign = 2000 -- 八日签到
}

-- 聊天频道定义
define.chatChannelDef = {
    world   = 1, -- 世界
    system  = 2, -- 系统
    guild   = 3, -- 公会
    private = 4, -- 私聊
    friend  = 5 -- 好友
}

-- 活动事件定义
define.activeEventDefine = {
    open  = 1, -- 活动开启
    close = 2 -- 活动关闭
}

-- 活动类型定义
define.activeTypeDefine = {
    sevenTask = 1, -- 七日任务(嘉年华)
    eightSign = 2, -- 八日签到
    mail      = 3 -- 邮件活动

}

define.cashDeskId = 100001

-- npc 类型
define.sellType = {
    pass         = 0, -- 门口路过
    customerBuy  = 1, -- npc购买
    customerSell = 2, -- npc售卖
    heroBuy      = 3, -- 英雄购买
    princessBuy  = 4, -- 公主购买
    workerItem   = 6, -- 工匠卖物品
    selllEquip   = 7, -- 工匠卖装备
    guide        = 8, -- 引导npc购买
    trade        = 9, -- 交易npc
    fouluma      = 10 -- 图纸npc
}

-- 服务器通知客户端弹框类型
define.tipsType = {
    defalut   = 1, -- 默认弹框
    paomadeng = 2 -- 跑马灯
}

-- 装备词条类型
define.equipHeadwordType = {
    main = 1, -- 主词条
    sub  = 2 -- 副词条
}

-- 充值结果
define.chargeResult = {
    fail    = 0,
    success = 1
}

-- 充值类型
define.chargeTypeDef = {
    default         = 0, -- 默认充值/充值界面里面充值
    firstChargeGift = 1 -- 首冲礼包
}

define.studyType = {
    normal = 1 -- 普通培养点
}

define.heroAttrType = {
    HP_CURRENT = 1,  -- 当前生命
    HP         = 2,  -- 生命
    ATK        = 3,  -- 攻击
    DEF        = 4,  -- 防御
    DEX        = 5,  -- 速度
    EVA        = 6,  -- 闪避
    CRI        = 7,  -- 暴击
    CRID       = 8,  -- 暴伤
    BRK        = 9,  -- 击破
    TRT        = 10, -- 治疗加成
    BUFA       = 11, -- 效果命中
    BUFB       = 12, -- 效果抵抗
    BOLDNESS   = 13, -- 气魄
    DEMEANOR   = 14, -- 风度
    LOGISTICS  = 15, -- 运筹
    REACT      = 16, -- 反应
    WEAK_SWORD = 20, -- 弱点加成_利刃
    WEAK_HAM   = 21, -- 弱点加成_重具
    WEAK_BOW   = 22, -- 弱点加成_远程
    WEAK_FAN   = 23, -- 弱点加成_奇兵
    WEAK_METAL = 24, -- 弱点加成_金
    WEAK_WOOD  = 25, -- 弱点加成_木
    WEAK_WATER = 26, -- 弱点加成_水
    WEAK_FIRE  = 27, -- 弱点加成_火
    WEAK_EARTH = 28, -- 弱点加成_土

    WEAK_SWORD_RESIST = 30, -- 弱点抵抗_利刃
    WEAK_HAM_RESIST   = 31, -- 弱点抵抗_重具
    WEAK_BOW_RESIST   = 32, -- 弱点抵抗_远程
    WEAK_FAN_RESIST   = 33, -- 弱点抵抗_奇兵
    WEAK_METAL_RESIST = 34, -- 弱点抵抗_金
    WEAK_WOOD_RESIST  = 35, -- 弱点抵抗_木
    WEAK_WATER_RESIST = 36, -- 弱点抵抗_水
    WEAK_FIRE_RESIST  = 37, -- 弱点抵抗_火
    WEAK_EARTH_RESIST = 38, -- 弱点抵抗_土

    DEFENCE_PENETRATE        = 50,  -- 防御无视
    DMG_UP                   = 51,  -- 伤害提升
    DMG_DOWN                 = 52,  -- 伤害降低
    VULNER_UP                = 53,  -- 易伤提升
    RES_PENETRATE            = 54,  -- 抗性穿透
    RES_REMOVE               = 55,  -- 抗性移除
    TREAT_CORRECTION         = 56,  -- 回复修正
    BREAK_CORRECTION         = 57,  -- 破韧修正
    WEAK_CORRECTION          = 58,  -- 弱点暴露
    TAU_CORRECTION           = 59,  -- 嘲讽修正
    TAU                      = 100, -- 嘲讽值
    HEALTH_CURRENT_NOW_RATIO = 101, -- 当前生命(百分比) = 生命上限n%
    HEALTH_RATIO             = 102, -- 生命上限(百分比)
    ATTACK_RATIO             = 103, -- 攻击(百分比)
    DEFENCE_RATIO            = 104, -- 防御(百分比)
    DEXTERITY_RATIO          = 105 -- 速度(百分比)
}

-- 申请状态
define.applyStatus = 
{
    none = 0, -- 未申请
    apply = 1, -- 已申请
}

-- 同意/拒绝状态
define.agreeOrRefuseStatus = 
{
    agree = 0, -- 同意
    refuse = 1, -- 拒绝
}

-- 工坊id定义
define.workShopIdDef =
{
    collect = 1, -- 采集
    autoMakeEquip = 2, -- 装备制造
    shop = 3, -- 商店
    alchemy = 4, -- 炼丹
}

-- 快速完成类型
define.shopTypeDef = 
{
    production = 1, -- 装备制造
    shopExtend = 2, -- 土地拓展
    furnitureUp = 3 -- 家具升级
}


return define
