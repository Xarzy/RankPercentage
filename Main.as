AppController@ appController; // Declaración global

void Main() {
    trace("Creando appController...");
    @appController = AppController();
    trace("Iniciando Proceso appController.Play...");
    appController.Play();
}


[SettingsTab name="General"]
void SettingsTabGeneral() {
    if (appController !is null) appController.SettingsTabGeneral();
}

void Render() {
    if (appController !is null) appController.Render();
}