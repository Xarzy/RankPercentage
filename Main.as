// Settings
float leaderboardP = 1.0f;
const string SETTINGS_FILE = "leaderboard_settings.json";
const string PLG_NAME = "TestPlugin";

void LoadSettings() {
    if (!IO::FileExists(IO::FromStorageFolder(SETTINGS_FILE))) {
        SaveSettings(); // crea archivo por primera vez
        return;
    }

    IO::File file(IO::FromStorageFolder(SETTINGS_FILE), IO::FileMode::Read);

    string content = file.ReadToEnd();
    file.Close();

    Json::Value@ json = Json::Parse(content);
    if (json is null || !json.HasKey("leaderboardP")) {
        warn("⚠️ Configuración inválida.");
        return;
    }

    leaderboardP = float(json["leaderboardP"]);
}

void SaveSettings() {
    Json::Value@ json = Json::Object();
    json['leaderboardP'] = leaderboardP;

    string path = (IO::FromStorageFolder("") + SETTINGS_FILE);
    print(path);
    IO::File file(path, IO::FileMode::Write);
    file.Write(Json::Write(json, true));
    file.Close();
}

[SettingsTab name="General"]
void Prueba() {
    const float MIN = 0.0f;
    const float MAX = 100.0f;
    string format = "%.2f";

    float oldValue = leaderboardP;
    leaderboardP = UI::InputFloat("Percentage Leaderboard", leaderboardP, 1.0f, 1.0f, format);

    if (leaderboardP > MAX) leaderboardP = MAX;
    else if (leaderboardP < MIN) leaderboardP = MIN;

    if (leaderboardP != oldValue) {
        SaveSettings(); // solo guarda si cambia
    }
}

void ConstructBase() {
    IO::FromStorageFolder(""); // Constructs PluginStorage Folder
}

// Variables globales
string mapUid = "";
string mapName = "";
uint totalPlayers = 0;
uint playerPos = 0;
uint playerScore = 0;
uint lastPlayerScore = 0;
uint targetScore = 0;
uint rankTarget = 0;

bool hasMap = false;
bool hasRequested = false;
bool dataReady = false;

void Main() {
    ConstructBase();
    LoadSettings();
    auto app = GetApp();

    while (true) {
        auto currentMap = app.RootMap;

        // Entramos a un mapa
        if (!hasMap && currentMap !is null) {
            auto map = cast<CGameCtnChallenge@>(currentMap);
            if (map !is null && map.MapInfo !is null) {
                mapUid = map.MapInfo.MapUid;
                mapName = map.MapName;
                hasMap = true;
                dataReady = false;
                hasRequested = false;
                print("📌 Mapa detectado: " + mapName + " | UID: " + mapUid);
            }
        }

        // Salimos del mapa
        if (hasMap && currentMap is null) {
            print("🔙 Saliste del mapa.");
            hasMap = false;
            hasRequested = false;
            dataReady = false;
            mapUid = "";
            mapName = "";
        }

        // Pedir datos si es necesario
        if (hasMap && !hasRequested && mapUid != "") {
            hasRequested = true;

            totalPlayers = GetPlayerCount(mapUid);
            playerPos = GetPlayerPos(mapUid,playerScore);
            lastPlayerScore = playerScore == 1 ? ~0 : playerScore; // guardar para comparar después
            targetScore = GetTargetScore(mapUid, leaderboardP,rankTarget);

            dataReady = true;
        }

        // Verificar si hay mejora
        if (hasMap && dataReady) {
            uint currentScore;
            GetPlayerPos(mapUid,currentScore);
            if (currentScore < lastPlayerScore && currentScore > 0) {
                print("🔄 Tiempo personal mejorado. Actualizando datos...");
                // Resetear para volver a hacer el proceso completo
                hasRequested = false;
                dataReady = false;
            }
        }

        yield();
    }
}


int GetPlayerCount(string &in mapUid) {
    const string TM_WAALRUS_API = "https://tm.waalrus.xyz/" + "np/map/" + mapUid;
    Net::HttpRequest@ req = Net::HttpRequest();

    req.Url = TM_WAALRUS_API;
    req.Method = Net::HttpMethod::Get;
    
    req.Start();

    while(!req.Finished()) yield();

    if (req.ResponseCode() != 200) {
        return -1;
    }

    const Json::Value@ json = Json::Parse(req.String());

    if (json["player_count"].GetType() == Json::Type::Null) {
        return -1;
    }

    return json.Get("player_count");
}

int GetPlayerPos(string &in mapUid, int &out score) {
    const string URL = NadeoServices::BaseURLLive() + "/api/token/leaderboard/group/Personal_Best/map/" + mapUid + "/surround/0/0?score=0&onlyWorld=true";

    Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", URL);

    req.Start();

    while (!req.Finished()) {
        yield();
    }

    if (req.ResponseCode() != 200) {
        return -1;
    }

    Json::Value json = Json::Parse(req.String());

    Json::Value tops = json['tops'];

    if (Json::Type::Array != tops.GetType()) {
        trace("Failed to get leaderboards");
        return -1;
    }

    Json::Value world_top = tops[0]['top'];

    if (Json::Type::Array != world_top.GetType()) {
        trace("Failed to get player's world position");
        return -1;
    }

    int position = world_top[0].Get('position', -1);

    score = world_top[0].Get('score', -1);

    return position;
}

int GetTargetScore(string &in mapUid, int &in leaderboardTarget, int &out rank) {
    uint rankTarget = uint(totalPlayers / (100/leaderboardTarget));
    rank = rankTarget;

    if (rankTarget > 10000) {
        return -2;
    }
   
    const string URL = NadeoServices::BaseURLLive() + "/api/token/leaderboard/group/Personal_Best/map/" + mapUid + "/top?length=1&onlyWorld=true&offset=" + (rankTarget - 1);

    Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", URL);
    req.Start();

    while (!req.Finished()) yield();

    print(req.String());

    Json::Value json = Json::Parse(req.String());

    Json::Value tops = json['tops'];
    Json::Value top = tops[0]['top'];

    return int(top[0]['score']);
}

string Pad2(uint val) {
    return (val < 10 ? "0" : "") + val;
}

string Pad3(uint val) {
    if (val < 10) return "00" + val;
    if (val < 100) return "0" + val;
    return "" + val;
}

string FormatTime(uint ms) {
    uint hours = ms / 3600000;
    ms %= 3600000;

    uint minutes = ms / 60000;
    ms %= 60000;

    uint seconds = ms / 1000;
    ms %= 1000;

    string msStr = Pad3(ms);

    if (hours > 0) {
        // Formato HH:MM:SS.mmm
        return hours + ":" + minutes + ":" + Pad2(seconds) + "." + msStr;
    } else if (minutes > 0) {
        // Formato MM:SS.mmm
        return minutes + ":" + Pad2(seconds) + "." + msStr;
    } else {
        // Solo segundos: SS.mmm (sin ceros delante)
        return "" + seconds + "." + msStr;
    }
}



void Render() {
    if (!hasMap || !dataReady) return;

    UI::Begin("a", UI::WindowFlags::NoResize | UI::WindowFlags::NoTitleBar | UI::WindowFlags::AlwaysAutoResize);

    UI::Text(Icons::Terminal + " Rank " + rankTarget + "/" + totalPlayers + " (Top " + Text::Format("%.2f", leaderboardP) + "%)");

    if (rankTarget <= 10000) {
        UI::Text(Icons::Search + " " + Text::Format("%.2f", leaderboardP) + "% Time: " + FormatTime(targetScore) + " ");
        UI::SameLine();

        bool isBehind = playerScore > targetScore;
        vec4 color = playerScore == 1 ? vec4(0.8, 0.8, 0.8, 1) : isBehind ? vec4(1, 0.3, 0.3, 1) : vec4(0.3, 0.6, 1, 1); // rojo o azul si hay pb en el mapa, sino gris claro

        UI::PushStyleColor(UI::Col::Text, color);
        string text = (playerScore == 1 ? "No time" : FormatTime(Math::Abs(playerScore - targetScore)));
        playerScore == 1 ? UI::Text(text) : UI::Text((isBehind ? "+" : "-") + text);

        UI::PopStyleColor();
    } else if (targetScore == -2) {
        UI::PushStyleColor(UI::Col::Text, vec4(1, 0, 0, 1));
        UI::Text(Icons::Lock + "Delta Time is not available.");
        UI::PopStyleColor();
    }
    UI::End();
}