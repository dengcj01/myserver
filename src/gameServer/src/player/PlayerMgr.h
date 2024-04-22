#pragma once

#include <stdint.h>

#include <unordered_map>
#include <vector>

#include "../../../common/Singleton.h"
#include "../../../common/net/Data.h"

class Player;

class PlayerMgr : public Singleton<PlayerMgr>
{
public:
	~PlayerMgr();

	std::unordered_map<uint64_t, Player *> &getOnlinePlayers()
	{
		return playerList_;
	}

	void closeAllPlayer();
	Player *newPlayer(uint64_t sessionId, uint64_t csessionId, uint64_t pid);
	Player *getPlayer(uint64_t csessionId);
	Player *getPlayerById(uint64_t pid);
	Player *fakeLogin(uint64_t pid);
	Player *getFakePlayer(uint64_t pid);
	std::vector<std::string> loadFakePlayerData(uint64_t pid, uint8_t moduleId);
	void removePlayer(uint64_t sessionId) { playerList_.erase(sessionId); }
	void removePlayerById(uint64_t pid) { playerIdList_.erase(pid); }
	void addPlayerById(uint64_t pid, Player* player) { playerIdList_.emplace(pid, player); }
	void playerLogout(Player *player, bool save = true, bool db = true);
	void playerLogin(Player *player);
	void releaseFakePlayer(Player *player);
	void saveFakePlayerData(uint64_t pid);
	void savePlayerModuleData(uint64_t pid);
	bool isOnline(uint64_t sessionId) { return playerList_.find(sessionId) != playerList_.end(); }
	void cleanPlayerLuaModuleData(uint64_t pid);
	std::unordered_map<uint64_t, uint8_t> getZeroList() { return zeroList_; }
	void cleanZeroList() { zeroList_.clear(); }
	size_t getOnlineCnt() { return playerList_.size(); }

	void testLoad();
	void testSave();

	static void fakeLoginCallback(Args *args);


	std::unordered_map<uint64_t, Player *> playerList_;		// 玩家会话->玩家对象映射
	std::unordered_map<uint64_t, Player *> playerIdList_;	// 玩家id->对家对象映射,生命周期跟随上面
	std::unordered_map<uint64_t, Player *> fakePlayerList_; // 伪登录玩家
	std::unordered_map<uint64_t, uint8_t> zeroList_; // 刚好0点登入的玩家
};

#define gPlayerMgr PlayerMgr::instance()