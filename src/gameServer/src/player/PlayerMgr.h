#pragma once

#include <stdint.h>

#include <unordered_map>
#include <vector>

#include "../../../common/Singleton.h"
#include "../../../common/net/Data.h"
#include "../../../common/pb/Player.pb.h"


class Player;

class PlayerMgr : public Singleton<PlayerMgr>
{
public:
	~PlayerMgr();

	std::unordered_map<uint64_t, Player *> getOnlinePlayers()
	{
		return playerIdList_;
	}

	std::unordered_map<uint64_t, Player *>getFakeList()
	{
		return fakeList_;
	}

	void removeFakePlayer(uint64_t pid);
	bool isFakeLoad(uint64_t pid, uint8_t moduleId);
	Player* fakeLoad(uint64_t pid, uint8_t moduleId);
	void closeAllPlayer(uint8_t useDb = 1);
	Player *newPlayer(uint64_t sessionId, uint64_t csessionId, uint64_t pid);
	Player *getPlayer(uint64_t csessionId);
	Player *getPlayerById(uint64_t pid);
	void removePlayerById(uint64_t pid) { playerIdList_.erase(pid); }
	void removePlayerBySessionId(uint64_t csessionId) { playerList_.erase(csessionId); }
	void addPlayerById(uint64_t pid, Player* player) { playerIdList_.emplace(pid, player); }
	void playerLogout(Player *player, bool save = true, uint8_t useDb = 0);
	void playerLogin(Player *player);
	bool isOnline(uint64_t sessionId) { return playerList_.find(sessionId) != playerList_.end(); }
	void cleanPlayerLuaModuleData(uint64_t pid);
	size_t getOnlineCnt() { return playerIdList_.size(); }
	void regPlayerBaseInfo2Master(Player* player); 
	void updatePlayerBaseInfo2Master(uint64_t pid, const char* str);
	void changePlayerName(Player* player, const char* name);


	std::unordered_map<uint64_t, Player *> playerList_;		// 玩家会话->玩家对象映射
	std::unordered_map<uint64_t, Player *> playerIdList_;	// 玩家id->对家对象映射,生命周期跟随上面
	std::unordered_map<uint64_t, Player *> fakeList_;	// 伪登入玩家列表
	std::unordered_map<uint64_t, std::unordered_map<uint8_t, uint8_t>> fakeModuleList_; // 伪登入已经加载的玩家模块列表
	
};

#define gPlayerMgr PlayerMgr::instance()