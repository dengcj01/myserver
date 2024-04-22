#pragma once

#include <stdint.h>
#include <string>
#include <unordered_map>
#include "../../../common/pb/ServerCommon.pb.h"
#include "../pb/Bag.pb.h"

class Bag;

class Player
{
public:
	Player();
	~Player();

	inline uint64_t getSessionId() { return sessionId_; }
	inline uint64_t getCsessionId() { return csessionId_; }
	inline uint64_t getPid() { return pid_; }
	void initBaseData(const PlayerBaseData &res);
	void initModuleData(uint8_t moduleId, const std::string& data);
	void saveData(bool db=true);
	void saveBaseData(bool db=true);
	void saveBagData(bool db = true);
	static void saveModuleData(uint64_t pid, uint8_t mod = 0, bool db = true);
	void initBagData(ResReturnPlayerBagData &res);
	inline bool canFakeLoad(uint8_t moduleId) { return fakeModuleIdList_.find(moduleId) == fakeModuleIdList_.end(); }
	inline void addFakeModuleId(uint8_t moduleId) { fakeModuleIdList_.emplace(moduleId, 1); }
	inline void removeFakeModuleId(uint8_t moduleId) { fakeModuleIdList_.erase(moduleId); }
	bool itemEnough(std::map<uint32_t, uint64_t> items);
	void costItems(std::map<uint32_t, uint64_t> cost, const char *logDesc = "", const char *extra = "");
	std::map<uint32_t, uint64_t> addItems(std::map<uint32_t, uint64_t> add, const char *logDesc = "", const char *extra = "");
	uint64_t getItemCount(uint32_t itemId);
	void removeItemById(uint32_t itemId, const char *desc = "", const char *extra = "");
	void removeItemByGuid(uint64_t guid, const char *desc = "", const char *extra = "");
	std::unique_ptr<ResBagData> packBagData();
	void save();

	uint32_t getCreateTime() { return createTime_; }
	const std::string &getName() { return name_; }
	const std::string &getIcon() { return icon_; }
	const std::string &getAccount() { return account_; }
	const std::string &getPf() { return pf_; }
	uint64_t getPower() { return power_; }
	uint32_t getLevel() { return level_; }
	uint32_t getVip() { return vip_; }
	uint32_t getExp() { return exp_; }
	uint32_t getLoginTime() { return loginTime_; }
	uint64_t getGuildId() { return guildId_; }
	uint32_t getChargeVal() { return chargeVal_; }
	uint32_t getTitle() { return title_; }
	uint32_t getHeadIcon() { return headIcon_; }
	uint32_t getSkin() { return skin_; }


public:
	uint64_t sessionId_;
	uint64_t pid_;
	std::string name_;
	std::string icon_;
	std::string account_;
	std::string pf_;
	uint32_t createTime_;
	uint64_t power_;
	uint32_t level_;
	uint32_t vip_;
	uint32_t exp_;
	uint32_t loginTime_;
	uint32_t logoutTime_; // 上次下线的时间.用于本次登入计算离线时间
	uint64_t guildId_;
	uint32_t chargeVal_;
	uint32_t title_;
	uint32_t headIcon_;
	uint32_t skin_;
	uint32_t fromServerId_;
	uint64_t csessionId_;
	uint32_t saveTime_ = 0;

	std::string extra_;
	std::unordered_map<int, uint8_t> fakeModuleIdList_;
	std::string timeId_;
	Bag *bag_;
};
