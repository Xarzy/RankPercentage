class SettingsManager : IDAOSettings {
    float leaderboardP;
    string settingsFile = "leaderboard_target.json";
    string pluginName = "RankPercentage";

    SettingsManager() {
        leaderboardP = 10.0f;
        trace("settingsManager creado");
    }
    
    void LoadSettings() {
        trace("Cargando Ajustes...");
        if (!IO::FileExists(IO::FromStorageFolder(settingsFile))) {
            warn("El archivo de ajustes no existe, se creará uno nuevo.");
            SaveSettings(); // crea archivo por primera vez
            return;
        }

        IO::File file(IO::FromStorageFolder(settingsFile), IO::FileMode::Read);

        string content = file.ReadToEnd();
        file.Close();

        Json::Value@ json = Json::Parse(content);
        if (json is null || !json.HasKey("leaderboardP")) {
            warn("⚠️ Configuración inválida.");
            return;
        }

        leaderboardP = float(json["leaderboardP"]);
        trace("Ajustes cargados, leaderboardTarget es " + leaderboardP);
    }

    void SaveSettings() {
        trace("Guardando ajustes...");
        Json::Value@ json = Json::Object();
        json['leaderboardP'] = leaderboardP;

        string path = (IO::FromStorageFolder("") + settingsFile);
        print(path);
        IO::File file(path, IO::FileMode::Write);
        file.Write(Json::Write(json, true));
        file.Close();
        trace("Ajustes Guardados.");
    }

    void SettingsTabGeneral() {
        const float MIN = 0.0f;
        const float MAX = 100.0f;
        const string FORMAT = "%.2f";

        float oldValue = leaderboardP;
        leaderboardP = UI::InputFloat("Percentage Leaderboard", leaderboardP, 1.0f, 5.0f, FORMAT);

        if (leaderboardP > MAX) leaderboardP = MAX;
        else if (leaderboardP < MIN) leaderboardP = MIN;

        if (leaderboardP != oldValue) {
            SaveSettings(); // solo guarda si cambia
        }
    }

    void ConstructBase() {
        trace("Construyendo base...");
        IO::FromStorageFolder(""); // Constructs PluginStorage Folder
    }

    float getLeaderboardP() {
        return leaderboardP;
    }
}