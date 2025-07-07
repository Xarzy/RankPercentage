class MapStateManager {
    CGameCtnApp@ app;
    SettingsManager@ sm;
    ErrorTypes response;
    SGamePlaygroundUIConfig::EUISequence lastSequence;

    string mapUid;
    string mapName;

    int totalPlayers;
    int playerPos;
    int playerScore;
    int lastPlayerScore;
    int targetScore;
    int rankTarget;
    bool hasMap;

    bool hasRequested;
    bool dataReady;
    bool finished;

    MapStateManager(SettingsManager@ _sm) {
        @app = GetApp();
        @sm = _sm;
        lastSequence = GetCurrentUISequence();
        mapUid = "";
        mapName = "";
        totalPlayers = 0;
        playerPos = 0;
        playerScore = 0;
        lastPlayerScore = 0;
        targetScore = 0;
        rankTarget = 0;
        hasMap = false;
        hasRequested = false;
        dataReady = false;
        finished = false;
        trace("mapStateManager creado");
    }

    void Update() {
        CGameCtnChallenge@ currentMap = app.RootMap;

        // Entramos a un mapa
        if (!hasMap && currentMap !is null) {
            auto map = cast<CGameCtnChallenge@>(currentMap);
            if (map !is null && map.MapInfo !is null) {
                mapUid = map.MapInfo.MapUid;
                mapName = map.MapName;
                hasMap = true;
                dataReady = false;
                hasRequested = false;
                trace("Mapa detectado: " + mapName + " | UID: " + mapUid);
            }
        }

        // Salimos del mapa
        if (hasMap && currentMap is null) {
            trace("Saliste del mapa.");
            hasMap = false;
            hasRequested = false;
            dataReady = false;
            finished = false;
            mapUid = "";
            mapName = "";
        }

        // Pedir datos si es necesario
        if (hasMap && !hasRequested && mapUid != "") {
            trace("Actualizando datos...");
            hasRequested = true;

            response = ErrorTypes::OK;

            totalPlayers = LeaderboardServices::GetPlayerCount(mapUid);

            if (totalPlayers > -1) {
                playerScore = LeaderboardServices::GetPlayerScore(@app.Network, mapUid);
                if (playerScore != -1) trace("Tiempo del jugador: " + playerScore);
                else trace("No pb found!");
                lastPlayerScore = playerScore == 0 ? ~0 : playerScore; // guardar para comparar después
                playerPos = LeaderboardServices::GetPlayerPos(mapUid,playerScore);
                if (playerPos > -1) {
                    targetScore = LeaderboardServices::GetTargetScore(mapUid, totalPlayers, sm.leaderboardP,rankTarget);
                    if (targetScore < 0) {
                        response = ErrorTypes(targetScore);
                    }
                } else response = ErrorTypes(playerPos);
            } else response = ErrorTypes(totalPlayers);

            dataReady = true;
        }

        // Verificar si hay mejora
        if (hasMap && dataReady && CheckEndOfMap()) {
            hasRequested = false;
            dataReady = false;
            finished = true;
        }
    }

    bool CheckEndOfMap() {
        if (app.CurrentPlayground is null) return false;

        auto pg = cast<CGameCtnPlayground@>(app.CurrentPlayground);
        if (pg is null || pg.GameTerminals.Length == 0) return false;

        auto terminal = pg.GameTerminals[0];
        if (terminal is null) return false;

        bool res = false;

        auto sequence = terminal.UISequence_Current;
        if (sequence != lastSequence) {
            if (sequence == SGamePlaygroundUIConfig::EUISequence::Finish) {
                trace("🏁 ¡Carrera finalizada!");
                res = true;
            }
            lastSequence = sequence;
        }
        return res;
    }

    SGamePlaygroundUIConfig::EUISequence GetCurrentUISequence() {
        if (app is null || app.CurrentPlayground is null) return SGamePlaygroundUIConfig::EUISequence::None;

        auto pg = cast<CGameCtnPlayground@>(app.CurrentPlayground);
        if (pg is null || pg.GameTerminals.Length == 0) return SGamePlaygroundUIConfig::EUISequence::None;

        auto terminal = pg.GameTerminals[0];
        if (terminal is null) return SGamePlaygroundUIConfig::EUISequence::None;

        return terminal.UISequence_Current;
    }
}
