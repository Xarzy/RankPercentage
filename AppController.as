class AppController {
    SettingsManager@ settingsManager;
    MapStateManager@ mapStateManager;
    UIRenderer@ uiRenderer;

    AppController() {
        @settingsManager = SettingsManager();
        @mapStateManager = MapStateManager(@settingsManager);
        @uiRenderer = UIRenderer();
    }

    void Play() { 
        settingsManager.ConstructBase();
        settingsManager.LoadSettings();
        trace("Entrando a actualizar datos...");
        while (true) {
            mapStateManager.Update();
            yield();
        }
    }

    void Render() {
        appController.uiRenderer.Render(@appController.mapStateManager);
    }

    void SettingsTabGeneral() {
        appController.settingsManager.SettingsTabGeneral();
    }
}
