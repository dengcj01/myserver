#pragma once

#include <stdint.h>
#include <string>
#include <unordered_map>
#include "../../../common/pb/Player.pb.h"


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
	void saveData(uint8_t useDb = 0);
	void saveBaseData(uint8_t useDb = 0);
	void saveModuleData(uint64_t pid, std::map<uint8_t, std::string> datas, uint8_t useDb = 0);
	void save();
	void notifyPlayerBaseData(uint64_t sessionId, uint64_t csessionId);

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
	uint32_t getFromServerId() {return fromServerId_;}
	int32_t getSex() { return sex_; }

	void setLevel(uint32_t lv);
	void setBanTime(uint32_t banTime) { banTime_ = banTime; save();}
	void setBanReason(std::string banReason) { banReason_ = banReason; save();}
	void setName(const char* name) {name_ = name; save();}
	uint8_t getGmLevel() {return gmlv_;}
	void setGmLevel() {gmlv_ = 1;};
	bool isZeroTimeLogin() {return zeroTimeLogin_;}
	void addChargeVal(uint32_t val) {chargeVal_ += val; save(); }
	void setGuildId(uint64_t guildId) {guildId_ = guildId; save(); }
	
public:
	uint64_t sessionId_;
	uint64_t pid_ = 0;
	std::string name_;
	std::string icon_;
	std::string account_;
	std::string pf_;
	uint32_t createTime_;
	uint64_t power_;
	uint32_t level_ = 1;
	uint32_t vip_;
	uint32_t exp_;
	uint32_t loginTime_;
	uint32_t logoutTime_; // 上次下线的时间.用于本次登入计算离线时间
	uint64_t guildId_ = 0;
	uint32_t chargeVal_;
	uint32_t title_;
	uint32_t headIcon_;
	uint32_t skin_;
	uint16_t fromServerId_;
	uint64_t csessionId_;
	uint32_t saveTime_ = 0;
	uint32_t firstLoginTime_=0;
	uint32_t banTime_ = 0;
	uint8_t gmlv_ = 0;
	uint8_t sex_ = 0;
	std::string banReason_;
	bool zeroTimeLogin_ = false;
	std::string extra_;
	std::string timeId_;

};
