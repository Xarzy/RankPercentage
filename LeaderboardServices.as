namespace LeaderboardServices {
    /*
     * Returns aproximate player count given a mapUid.
     */

    int GetPlayerCount(string &in mapUid) {
        const string TM_WAALRUS_API = "https://tm.waalrus.xyz/np/map/" + mapUid;
        Net::HttpRequest@ req = Net::HttpRequest();

        req.Url = TM_WAALRUS_API;
        req.Method = Net::HttpMethod::Get;
        
        req.Start();

        while(!req.Finished()) yield();

        print(req.String());

        if (req.ResponseCode() != 200) {
            error("Bad Response.");
            return ErrorTypes::BAD_RESPONSE;
        }

        const Json::Value@ json = Json::Parse(req.String());

        if (json["player_count"].GetType() == Json::Type::Null) {
            error("Player Count is null.");
            return ErrorTypes::PLAYER_COUNT_IS_NULL;
        }

        int playerCount = json.Get("player_count");

        return playerCount > 0 ? playerCount : ErrorTypes::NO_RECORDS;
    }

    /*
     * Returns player position given a mapUid, and personal best score from given mapUid.
     * TODO: Use trackmania.io's API to retrieve custom maps records.
     */
    int GetPlayerPos(string &in mapUid, int &in score) {
        const string URL = NadeoServices::BaseURLLive() + "/api/token/leaderboard/group/Personal_Best/map/" + mapUid + "/surround/0/0?score=" + score;

        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", URL);

        req.Start();

        while (!req.Finished()) {
            yield();
        }
    
        print(req.String());

        if (req.ResponseCode() != 200) {
            error("Bad Response.");
            return ErrorTypes::NO_RECORDS;
        }

        const Json::Value@ json = Json::Parse(req.String());

        const Json::Value@ tops = json['tops'];

        if (tops is null || Json::Type::Array != tops.GetType()) {
            error("Failed to get leaderboards");
            return ErrorTypes::FAILED_LEADERBOARDS;
        }

        const Json::Value@ world_top = tops[0]['top'];

        if (Json::Type::Array != world_top.GetType()) {
            error("Failed to get player's world position");
            return ErrorTypes::NONEXISTENT_MAP;
        }
        
        return int(world_top[0].Get('position', -1));

    }

    /*
     * Returns target score given a mapUid, totalPlayers of the map, 
     * percentage target between 0-100, and rank target as an out parameter, in miliseconds.
     */
    int GetTargetScore(string &in mapUid, int &in totalPlayers, int &in leaderboardTarget, int &out rank) {
        uint rankTarget = leaderboardTarget == 0 ? 1 : uint(totalPlayers / (100/leaderboardTarget)); // Avoids division by zero exception
        rank = rankTarget = rankTarget != 0 ? rankTarget - 1 : 0;
        rank++;

        if (rankTarget > 10000) {
            return ErrorTypes::RANKTARGET_LIMIT_EXCEEDED;
        }
    
        const string URL = NadeoServices::BaseURLLive() + "/api/token/leaderboard/group/Personal_Best/map/" + mapUid + "/top?length=1&onlyWorld=true&offset=" + (rankTarget);

        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", URL);
        req.Start();

        while (!req.Finished()) yield();

        print(req.String());
        
        if (req.ResponseCode() != 200) {
            error("Bad Response.");
            return ErrorTypes::NO_RECORDS;
        }

        Json::Value json = Json::Parse(req.String());

        Json::Value tops = json['tops'];
        Json::Value top = tops[0]['top'];

        if (top.Length == 0) {
            error("Failed to get target's score");
            return ErrorTypes::NONEXISTENT_MAP;
        }

        return int(top[0]['score']);
    }

    int GetPlayerScore(CGameCtnNetwork@ &in network, string &in mapUid) {
		if (network.ClientManiaAppPlayground is null) return -1;
		if (network.ClientManiaAppPlayground.UserMgr is null) return -1;
		if (network.ClientManiaAppPlayground.ScoreMgr is null) return -1;

		auto userMgr = network.ClientManiaAppPlayground.UserMgr;

		MwId userId;
		if (userMgr.Users.Length > 0) {
			userId = userMgr.Users[0].Id;
		} else {
			userId.Value = uint(-1);
		}

		auto scoreMgr = network.ClientManiaAppPlayground.ScoreMgr;

		return scoreMgr.Map_GetRecord_v2(userId, mapUid, "PersonalBest", "", "TimeAttack", "");
	}
}